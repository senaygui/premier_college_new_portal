class Student < ApplicationRecord
  # #callbacks
  before_save :attributies_assignment
  before_save :student_id_generator
  after_save :student_semester_registration
  # before_create :assign_curriculum
  before_create :set_pwd
  after_save :student_course_assign

  # after_save :course_registration
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable
  #  , :authentication_keys => [:email]
  has_person_name
  # #associations
  belongs_to :department, optional: true
  belongs_to :section, optional: true

  belongs_to :program
  belongs_to :academic_calendar, optional: true
  has_one :student_address, dependent: :destroy
  has_many :add_courses, dependent: :destroy
  has_many :readmissions
  has_many :assessment_results
  accepts_nested_attributes_for :student_address
  has_one :emergency_contact, dependent: :destroy
  accepts_nested_attributes_for :emergency_contact
  has_many :semester_registrations, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_one_attached :grade_10_matric, dependent: :destroy
  has_one_attached :grade_12_matric, dependent: :destroy
  has_one_attached :coc, dependent: :destroy
  has_one_attached :highschool_transcript, dependent: :destroy
  has_one_attached :diploma_certificate, dependent: :destroy
  has_one_attached :degree_certificate, dependent: :destroy
  has_one_attached :undergraduate_transcript, dependent: :destroy
  has_one_attached :photo, dependent: :destroy
  has_many :student_grades, dependent: :destroy
  has_many :grade_reports
  has_many :course_registrations
  has_many :student_attendances
  has_many :assessments
  has_many :grade_changes
  has_one :school_or_university_information, dependent: :destroy
  accepts_nested_attributes_for :school_or_university_information
  has_many :student_courses, dependent: :destroy
  has_many :withdrawals, dependent: :destroy
  has_many :recurring_payments, dependent: :destroy
  has_many :add_and_drops, dependent: :destroy
  has_many :makeup_exams, dependent: :destroy
  has_many :payments
  has_many :transfers, dependent: :destroy
  validate :password_complexity
  # validates :student_grades, presence: true
  enum section_status: {
    no_assigned: 0,
    assigned: 1
  }
  def password_complexity
    if password.present? && !password.match(/^(?=.*[a-z])(?=.*[A-Z])/)
        errors.add :password,
                   'must be between 5 to 20 characters which contain at least one lowercase letter, one uppercase letter, one numeric digit, and one special character'
    end
  end

  # #scope
  scope :recently_added, -> { where('created_at >= ?', 1.week.ago) }
  scope :undergraduate, -> { where(study_level: 'undergraduate') }
  scope :graduate, -> { where(study_level: 'graduate') }
  scope :online, -> { where(admission_type: 'online') }
  scope :regular, -> { where(admission_type: 'regular') }
  scope :extention, -> { where(admission_type: 'extention') }
  scope :distance, -> { where(admission_type: 'distance') }
  scope :pending, -> { where(document_verification_status: 'pending') }
  scope :approved, -> { where(document_verification_status: 'approved') }
  scope :denied, -> { where(document_verification_status: 'denied') }
  scope :incomplete, -> { where(document_verification_status: 'incomplete') }
  scope :no_section, -> { where(section_id: nil) }

  def get_current_courses
    all_courses = program.curriculums.where(active_status: 'active').first.courses
                         .where(year:, semester:)
                         .order('year ASC', 'semester ASC')

    # Filter out courses where the student hasn't met the prerequisites
    all_courses.select do |course|
      passed_all_prerequisites?(self, course)
    end
  end

  def self.get_gc_students(graduation_status, graduation_year, program_id, study_level, admission_type)
    where(graduation_status:).where(study_level:).where(graduation_year:).where(program_id:).where(admission_type:).includes(:department).includes(:grade_reports)
  end

  def self.get_admitted_student(graduation_status, program_id, year, semester, study_level, admission_type)
    where(graduation_status:).where(study_level:).where(year:).where(semester:).where(program_id:).where(admission_type:).includes(:program)
  end

  def self.report_semester(year)
    Student.distinct.where(year:).select(:semester)
  end

  def get_added_course
    add_courses.where(status: 'approved').includes(:course).includes(:department)
  end

  def get_added_tution_fee
    get_added_course.collect { |add| (program_payment.tution_per_credit_hr * add.ects) }.sum
  end

  def self.fetch_student_for_report(status)
    where(graduation_status: status).includes(:department)
  end

  # def get_registration_fee
  #  return nil if program_payment.nil?
  #  program_payment.registration_fee
  # end

  def program_payment
    puts "Program ID: #{program_id}"
    puts "Batch: #{batch.strip}" if batch
    puts "Admission Date: #{admission_date}"

    payment = Payment.find_by(program_id:, batch: batch.strip)
    puts "Program Payment: #{payment.inspect}"
    registration_date = admission_date
    payment
  end

  def determine_semester
    semester = case admission_date.month
               when 1..9
                 1
                 # when 3..6
                 #   2
                 # when 7..9
                 #   3
                 # else
                 #   nil
               end
    puts "Determined Semester: #{semester}"
    semester
  end

  def get_registration_fee
    payment = program_payment
    return nil if payment.nil?

    base_fee = payment.registration_fee
    puts "Base Registration Fee: #{base_fee}"

    deadline = get_deadline(determine_semester)
    puts "Deadline: #{deadline}"

    if admission_date && deadline && admission_date > deadline
      puts "Adding Late Registration Fee: #{payment.late_registration_fee}"
      base_fee += payment.late_registration_fee
    end

    puts "Final Registration Fee: #{base_fee}"
    base_fee
  end

  def get_tuition_fee
    payment = program_payment
    return nil if payment.nil?

    base_fee = get_current_courses.collect do |oi|
      fee = oi.valid? ? (payment.tution_per_credit_hr * oi.credit_hour) : 0
      puts "Course: #{oi.inspect}, Fee: #{fee}"
      fee
    end.sum

    puts "Base Tuition Fee: #{base_fee}"

    penalty_fee = calculate_penalty_fee
    puts "Penalty Fee: #{penalty_fee}"

    total_fee = base_fee + penalty_fee
    puts "Total Tuition Fee: #{total_fee}"

    total_fee
  end

  def calculate_penalty_fee
    payment = program_payment
    return 0 if payment.nil?

    deadline, reg_date = get_deadline_and_registration_date
    puts "Deadline: #{deadline}, Admission Date: #{reg_date}"

    return 0 if deadline.nil? || reg_date.nil? || reg_date <= deadline

    days_late = (reg_date - deadline).to_i
    penalty_fee = payment.starting_penalty_fee.to_i + (days_late * payment.daily_penalty_fee.to_i)

    puts "Days Late: #{days_late}, Penalty Fee: #{penalty_fee}"

    penalty_fee
  end

  def get_deadline(semester)
    deadline = case semester
               when 1 then program_payment.semester_1_deadline
               when 2 then program_payment.semester_2_deadline
               when 3 then program_payment.semester_3_deadline
               end
    puts "Deadline for Semester #{semester}: #{deadline}"
    deadline
  end

  def get_deadline_and_registration_date
    deadline = get_deadline(determine_semester)
    puts "Final Deadline: #{deadline}, Admission Date: #{admission_date}"
    [deadline, admission_date]
  end

  # def get_tution_fee
  #  return nil if program_payment.nil?
  #  get_current_courses.collect { |oi| oi.valid? ? (program_payment.tution_per_credit_hr * oi.credit_hour) : 0 }.sum
  #  #total_fee = 0
  #  #get_current_courses.each do |course|
  #  #if student.batch.present? && course.valid?
  #  #  total_fee += program_payment.tution_per_credit_hr * course.ects
  #  #end
  #  #end
  # end

  def college_payment
    CollegePayment.find_by(study_level: study_level.strip, admission_type: admission_type.strip)
  end

  def full_name
    "#{first_name} #{middle_name} #{last_name}"
  end

  def add_student_registration(mode_of_payment = nil, out_of_batch = nil)
    SemesterRegistration.create do |registration|
      registration.student_id = id
      registration.program_id = program.id
      registration.department_id = program.department.id
      registration.student_full_name = "#{first_name.upcase} #{middle_name.upcase} #{last_name.upcase}"
      registration.student_id_number = student_id
      registration.created_by = "#{created_by}"
      registration.academic_calendar_id = AcademicCalendar.where(study_level: student.study_level,
                                                                 admission_type: student.admission_type).order(:created_at).last.id
      registration.year = year
      registration.semester = semester
      registration.program_name = program.program_name
      registration.admission_type = admission_type
      registration.study_level = study_level
      registration.created_by = last_updated_by
      registration.out_of_batch = out_of_batch if out_of_batch
      registration.mode_of_payment = mode_of_payment unless mode_of_payment.nil?
    end
  end

  private

  ## callback methods
  def passed_all_prerequisites?(student, course)
    prerequisites = Prerequisite.where(course_id: course.id)

    prerequisites.all? do |prerequisite|
      prerequisite_course = prerequisite.prerequisite
      student_grade = StudentGrade.find_by(student_id: student.id, course_id: prerequisite_course.id)

      # First check if student_grade is nil; if not, then check if the grade is not 'F'
      student_grade.nil? || student_grade.letter_grade != 'F'
    end
  end

  def set_pwd
    self[:student_password] = password
  end

  def attributies_assignment
    if document_verification_status == 'approved' && !academic_calendar.present?
      academic_calendar = AcademicCalendar.where(study_level: program.study_level,
                                                 admission_type: program.admission_type)
                                          .order('created_at DESC').first

      if academic_calendar.present?
        update_columns(
          academic_calendar_id: academic_calendar.id,
          department_id: program.department_id,
          # curriculum_version: program.curriculums.where(active_status: "active").last.curriculum_version,
          curriculum_version: program.curriculums.where(active_status: 'active').order(curriculum_active_date: :desc).first.curriculum_version,
          payment_version: program.payments.order('created_at DESC').first.version,
          batch: academic_calendar.batch || academic_calendar.calender_year_in_gc
        )
      end
    end
  end

  # def attributies_assignment
  #  if (self.document_verification_status == "approved") && (!self.academic_calendar.present?)
  #    self.update_columns(academic_calendar_id: AcademicCalendar.where(study_level: self.program.study_level, admission_type: self.program.admission_type).order("created_at DESC").first.id)
  #    self.update_columns(department_id: program.department_id)
  #    self.update_columns(curriculum_version: program.curriculums.where(active_status: "active").last.curriculum_version)
  #    self.update_columns(payment_version: program.payments.order("created_at DESC").first.version)
  #    self.update_columns(batch: AcademicCalendar.where(study_level: self.program.study_level).where(admission_type: self.program.admission_type).order("created_at DESC").first.calender_year_in_gc)
  #  end
  # end
  def student_id_generator
    if document_verification_status == 'approved' && !student_id.present?
      begin
        self.student_id = "#{program.program_code}/#{SecureRandom.random_number(1000..10_000)}/#{Time.now.strftime('%y')}"
      end while Student.where(student_id:).exists?
    end
  end

  def student_semester_registration
    if document_verification_status == 'approved' && year == 1 && semester == 1 && program.entrance_exam_requirement_status == false && semester_registrations.find_by(semester:).nil?
      # main one........if self.document_verification_status == "approved" && self.semester_registrations.empty? && self.year == 1 && self.semester == 1 && self.program.entrance_exam_requirement_status == false
      add_student_registration
    end
  end

  def self.get_online_student(_year, _semester)
     # Student.where(admission_type: 'online', year: year, semester: semester).joins(:course_registrations).where(course_registrations: {year: year, semester: semester})
     where(admission_type: 'online').select('id')
  end

  def student_course_assign
    if student_courses.empty? && document_verification_status == 'approved' && program.entrance_exam_requirement_status == false
      program.curriculums.where(curriculum_version:).last.courses.each do |course|
        StudentCourse.create do |student_course|
          student_course.student_id = id
          student_course.course_id = course.id
          student_course.course_title = course.course_title
          student_course.semester = course.semester
          student_course.year = course.year
          student_course.credit_hour = course.credit_hour
          student_course.ects = course.ects
          student_course.course_code = course.course_code
          student_course.created_by = created_by
        end
      end
    elsif student_courses.empty? && program.entrance_exam_requirement_status == true && document_verification_status == 'approved' && entrance_exam_result_status == 'Pass'
      program.curriculums.where(curriculum_version:).last.courses.each do |course|
        StudentCourse.create do |student_course|
          student_course.student_id = id
          student_course.course_id = course.id
          student_course.course_title = course.course_title
          student_course.semester = course.semester
          student_course.year = course.year
          student_course.credit_hour = course.credit_hour
          student_course.ects = course.ects
          student_course.course_code = course.course_code
        end
      end
    end
  end
end
