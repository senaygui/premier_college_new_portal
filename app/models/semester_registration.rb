class SemesterRegistration < ApplicationRecord
  after_save :change_course_registration_status
  after_save :assign_section_to_course_registration
  after_commit :semester_course_registration, on: :create
  after_save :generate_invoice
  after_save :add_admission_date
  scope :recently_added, -> { where('created_at >= ?', 1.week.ago) }
  scope :undergraduate, -> { where(study_level: 'undergraduate') }
  scope :graduate, -> { where(study_level: 'graduate') }
  scope :online, -> { where(admission_type: 'online') }
  scope :regular, -> { where(admission_type: 'regular') }
  scope :extention, -> { where(admission_type: 'extention') }
  scope :distance, -> { where(admission_type: 'distance') }
  # #associations
  belongs_to :student
  belongs_to :program
  belongs_to :department
  belongs_to :section, optional: true
  belongs_to :academic_calendar
  has_many :course_registrations, dependent: :destroy
  has_many :courses, through: :course_registrations, dependent: :destroy
  accepts_nested_attributes_for :course_registrations, reject_if: :all_blank, allow_destroy: true
  has_many :invoices, dependent: :destroy
  has_one :grade_report, dependent: :destroy
  has_many :recurring_payments, dependent: :destroy
  has_many :add_and_drops, dependent: :destroy

  def self.fetch_student_semester_registrations(id)
    where(department_id: id, is_back_invoice_created: false).where('remaining_amount=?',
                                                                   0.0).includes(:department).includes(:student)
  end

  def generate_grade_report
    # if !self.grade_report.present?

    any_course_missing_grade = course_registrations.where(enrollment_status: 'enrolled').any? do |course_registration|
      course_registration.student_grade.nil?
    end

    # Skip report generation if any enrolled course is missing a valid grade
    return if any_course_missing_grade

      GradeReport.create! do |report|
        report.semester_registration_id = id
        report.student_id = student.id
        report.academic_calendar_id = academic_calendar.id
        report.program_id = program.id
        report.department_id = program.department.id
        report.admission_type = student.admission_type
        report.study_level = student.study_level
        report.semester = student.semester
        report.year = student.year
        # report.dean_approval = 'pending'
        # report.department_approval = 'pending'
        # report.registrar_approval = 'pending'
       # ###report.total_credit_hour = self.course_registrations.where(enrollment_status: "enrolled").collect { |oi| (!!(oi.student_grade&.letter_grade != "I") && oi.student_grade.present? && !!(oi.student_grade&.letter_grade != "NG")) ? (oi.course.credit_hour) : 0 }.sum
       # ###report.total_grade_point = self.course_registrations.where(enrollment_status: "enrolled").collect { |oi| (!!(oi.student_grade&.letter_grade != "I") && oi.student_grade.present? && !!(oi.student_grade&.letter_grade != "NG")) ? (oi.student_grade.grade_point) : 0 }.sum

        report.total_credit_hour = course_registrations.where(enrollment_status: 'enrolled').collect do |oi|
          !!(oi.student_grade&.letter_grade != 'I') && oi.student_grade.present? && !!(oi.student_grade&.letter_grade != 'NG') ? oi.course.credit_hour : 0
        end.sum
        report.total_grade_point = course_registrations.where(enrollment_status: 'enrolled').collect do |oi|
          !!(oi.student_grade&.letter_grade != 'I') && oi.student_grade.present? && !!(oi.student_grade&.letter_grade != 'NG') ? oi.student_grade.grade_point : 0
        end.sum

        if student.grade_reports.empty?

          # report.total_course = self.course_registrations.count
          # report.total_credit_hour = self.course_registrations.where(enrollment_status: "enrolled").collect { |oi| ((oi.student_grade.letter_grade != "I") && (oi.student_grade.letter_grade != "NG")) ? (oi.course.credit_hour) : 0 }.sum
          # report.total_grade_point = self.course_registrations.where(enrollment_status: "enrolled").collect { |oi| ((oi.student_grade.letter_grade != "I") && (oi.student_grade.letter_grade != "NG")) ? (oi.student_grade.grade_point) : 0 }.sum

          # report.total_course = self.course_registrations.count
          # report.total_credit_hour = self.course_registrations.where(enrollment_status: "enrolled").collect { |oi| ((oi.student_grade.letter_grade != "I") && (oi.student_grade&.letter_grade != "NG")) ? (oi.course.credit_hour) : 0 }.sum
          # report.total_grade_point = self.course_registrations.where(enrollment_status: "enrolled").collect { |oi| ((oi.student_grade.letter_grade != "I") && (oi.student_grade&.letter_grade != "NG")) ? (oi.student_grade.grade_point) : 0 }.sum

          report.total_course = course_registrations.count
          report.total_credit_hour = course_registrations.where(enrollment_status: 'enrolled').collect do |oi|
            !!(oi.student_grade&.letter_grade != 'I') && oi.student_grade.present? && !!(oi.student_grade&.letter_grade != 'NG') ? oi.course.credit_hour : 0
          end.sum
          report.total_grade_point = course_registrations.where(enrollment_status: 'enrolled').collect do |oi|
            !!(oi.student_grade&.letter_grade != 'I') && oi.student_grade.present? && !!(oi.student_grade&.letter_grade != 'NG') ? (oi.course.credit_hour * oi.student_grade.grade_point) : 0
          end.sum
          # report.total_grade_point = self.course_registrations.collect { |oi| ((oi.student_grade.letter_grade != "I") && (oi.student_grade.letter_grade != "NG")) ? (oi.course.credit_hour * oi.student_grade.grade_point) : 0 }.sum

          report.sgpa = report.total_credit_hour == 0 ? 0 : (report.total_grade_point / report.total_credit_hour).round(2)

          report.cumulative_total_credit_hour = report.total_credit_hour
          report.cumulative_total_grade_point = report.total_grade_point
          report.cgpa = report.cumulative_total_credit_hour == 0 ? 0 : (report.cumulative_total_grade_point / report.cumulative_total_credit_hour).round(2)
          # p "*$#%*$########@*%)@#))))))))))))#########"
          # p report.cgpa
          # p report.sgpa

          if course_registrations.joins(:student_grade).pluck(:letter_grade).include?('I') || course_registrations.joins(:student_grade).pluck(:letter_grade).include?('NG')
            report.academic_status = 'Incomplete'
          else

            report.academic_status = if student.study_level.downcase == 'undergraduate'

                                       AddAcademicStatus.academic_status({ sgpa: report.sgpa, cgpa: report.cgpa },
                                                                                                  student)
                                     else
                                       AcademicStatusGraduate.get_academic_status(report:, student:)
                                     end

            if report.academic_status.strip != 'Academic Dismissal' && report.academic_status.strip != 'Academic Suspension'
              if program.program_semester > student.semester
                promoted_semester = student.semester + 1
                student.update_columns(semester: promoted_semester)
              elsif (program.program_semester == student.semester) && (program.program_duration > student.year)
                promoted_year = student.year + 1
                student.update_columns(semester: 1)
                student.update_columns(year: promoted_year)
              end
            else
              student.update_columns(account_status: 'inactive')
            end
          end
        elsif student.grade_reports.present?
          report.total_course = course_registrations.count

          # report.total_credit_hour = self.course_registrations.collect { |oi| ((oi.student_grade.letter_grade != "I") && (oi.student_grade.letter_grade != "NG")) ? (oi.course.credit_hour) : 0 }.sum
          # report.total_grade_point = self.course_registrations.collect { |oi| ((oi.student_grade.letter_grade != "I") && (oi.student_grade.letter_grade != "NG")) ? (oi.course.credit_hour * oi.student_grade.grade_point) : 0 }.sum
          # report.sgpa = report.total_credit_hour == 0 ? 0 : (report.total_grade_point / report.total_credit_hour).round(2)report.total_grade_point = self.course_registrations.collect { |oi| ((oi.student_grade.letter_grade != "I") && (oi.student_grade.letter_grade != "NG")) ? (oi.course.credit_hour * oi.student_grade.grade_point) : 0 }.sum

          report.total_credit_hour = course_registrations.where(enrollment_status: 'enrolled').collect do |oi|
            !!(oi.student_grade&.letter_grade != 'I') && oi.student_grade.present? && !!(oi.student_grade&.letter_grade != 'NG') ? oi.course.credit_hour : 0
          end.sum
          report.total_grade_point = course_registrations.where(enrollment_status: 'enrolled').collect do |oi|
            !!(oi.student_grade&.letter_grade != 'I') && oi.student_grade.present? && !!(oi.student_grade&.letter_grade != 'NG') ? (oi.course.credit_hour * oi.student_grade.grade_point) : 0
          end.sum
          # report.total_grade_point = self.course_registrations.where(enrollment_status: "enrolled").collect { |oi|
          # (!!(oi.student_grade&.letter_grade != "I") && oi.student_grade.present? && !!(oi.student_grade&.letter_grade != "NG")) ? (oi.course.credit_hour * oi.student_grade.grade_point) : 0}.sum
          report.sgpa = report.total_credit_hour == 0 ? 0 : (report.total_grade_point / report.total_credit_hour).round(2)
          report.cumulative_total_credit_hour = student.grade_reports.order('created_at DESC').first.cumulative_total_credit_hour + report.total_credit_hour
          report.cumulative_total_grade_point = student.grade_reports.order('created_at DESC').first.cumulative_total_grade_point + report.total_grade_point
          report.cgpa = (report.cumulative_total_grade_point / report.cumulative_total_credit_hour).round(2)

          # report.cumulative_total_credit_hour = report.total_credit_hour
          # report.cumulative_total_grade_point = report.total_grade_point
          # report.cgpa = report.cumulative_total_credit_hour == 0 ? 0 : (report.cumulative_total_grade_point / report.cumulative_total_credit_hour).round(2)

          if course_registrations.joins(:student_grade).pluck(:letter_grade).include?('I') || course_registrations.joins(:student_grade).pluck(:letter_grade).include?('NG')
            report.academic_status = 'Incomplete'
          else
            if student.study_level.downcase == 'undergraduate'
              report.academic_status = AddAcademicStatus.academic_status({ sgpa: report.sgpa, cgpa: report.cgpa },
                                                                         student)
            else
              report.academic_status = AcademicStatusGraduate.get_academic_status(report:, student:)
              # report.academic_status = self.student.program.grade_systems.last.academic_statuses.where("min_value <= ?", report.cgpa).where("max_value >= ?", report.cgpa).last.status
            end

            if report.academic_status.strip != 'Academic Dismissal' && report.academic_status.strip != 'Academic Suspension'
              if program.program_semester > student.semester
                promoted_semester = student.semester + 1
                student.update_columns(semester: promoted_semester)
              elsif (program.program_semester == student.semester) && (program.program_duration > student.year)
                promoted_year = student.year + 1
                student.update_columns(semester: 1)
                student.update_columns(year: promoted_year)
              end
            else
              student.update_columns(account_status: 'inactive')
            end
          end
        end

        report.created_by = created_by
      end
    # end
  end

  def approve_enrollment_status
    if finance_approval_status == 'approved' && registrar_approval_status == 'approved'
      course_registrations.update(enrollment_status: 'enrolled')
    end
  end

  def denied_enrollment_status
    if finance_approval_status == 'denied' && registrar_approval_status == 'denied'
      course_registrations.update(enrollment_status: 'denied')
    end
  end

  private

  def add_admission_date
    student.update(admission_date: Date.current) if semester == 1 && year == 1
  end

  def generate_invoice
    if mode_of_payment.present? && invoices.where(year:, semester:).empty?
      update_columns(is_back_invoice_created: true)
      Invoice.create do |invoice|
        invoice.semester_registration_id = id
        invoice.student_id = student.id
        invoice.department_id = department_id
        invoice.program_id = program_id
        invoice.academic_calendar_id = academic_calendar_id
        invoice.year = year
        invoice.semester = semester
        invoice.student_id_number = student_id_number
        invoice.student_full_name = student_full_name
        invoice.created_by = last_updated_by
        invoice.due_date = created_at + 10.day
        invoice.invoice_status = 'unpaid'

        invoice.registration_fee = student.get_registration_fee unless out_of_batch?
        tution_price = student.get_tuition_fee unless out_of_batch?
        tution_price = student.get_added_tution_fee if out_of_batch?

        invoice.invoice_number = SecureRandom.random_number(10_000_000)
        if mode_of_payment == 'Monthly Payment'
          invoice.total_price = (tution_price / 3 + 750)
          invoice.registration_fee = registration_fee / 4
        elsif mode_of_payment == 'Full Semester Payment'
          invoice.total_price = (tution_price + 750)
        elsif mode_of_payment == 'Half Semester Payment'
          invoice.total_price = (tution_price / 2 + 750)
          invoice.registration_fee = registration_fee / 2
        end
      end
    end
  end

  def semester_course_registration
    if finance_approval_status == 'pending' && registrar_approval_status == 'pending'
      all_courses = []

      courses_to_register = out_of_batch? ? student.get_added_course : student.get_current_courses

      # Filter out exempted courses for external transfer students
      # if student.is_a?(ExternalTransfer) && student.course_exemptions.any?
      #   exempted_course_ids = student.course_exemptions.pluck(:course_id)
      #   courses_to_register = courses_to_register.reject { |course| exempted_course_ids.include?(course.id) }
      # end

      courses_to_register.each do |course|
        course_registration = CourseRegistration.new(
          semester_registration_id: id,
          program_id: program.id,
          department_id: department.id,
          academic_calendar_id:,
          student_id: student.id,
          student_full_name:,
          course_id: course.id,
          academic_year: get_academic_year(semester, student),
          course_title: course.course_title,
          semester:,
          year:,
          created_by:
        )

        if course_registration.valid?
          all_courses << course_registration
        else
          # Handle the error (e.g., log it, notify the user, etc.)
          # puts "Cannot register for course #{course.course.course_title}: #{course_registration.errors.full_messages.join(', ')}"
        end
      end

      CourseRegistration.import! all_courses if all_courses.present?
    end
  end

  # def semester_course_registration
  #
  #  if self.finance_approval_status == "pending" && self.registrar_approval_status == "pending"
  #    # self.program.curriculums.where(curriculum_version: self.student.curriculum_version).last.courses.where(year: self.year, semester: self.semester).each do |co|
  #    all_courses = []
  #  if self.out_of_batch?
  #     self.student.get_added_course.each do |added|
  #      all_courses << CourseRegistration.new do |course_registration|
  #        course_registration.semester_registration_id = self.id
  #        course_registration.add_course_id = added.id
  #        course_registration.program_id = self.program.id
  #        course_registration.department_id = self.department.id
  #        course_registration.academic_calendar_id = self.academic_calendar_id
  #        course_registration.student_id = self.student.id
  #        course_registration.student_full_name = self.student_full_name
  #        course_registration.course_id = added.course_id
  #        course_registration.academic_year = get_academic_year(self.semester, self.student)
  #        course_registration.course_title = added.course.course_title
  #        course_registration.semester = self.semester
  #        course_registration.year = self.year
  #        course_registration.created_by = self.created_by
  #      end
  #     end
  #  else
  #    self.student.get_current_courses.each do |co|
  #      all_courses << CourseRegistration.new do |course_registration|
  #        course_registration.semester_registration_id = self.id
  #        course_registration.program_id = self.program.id
  #        course_registration.department_id = self.department.id
  #        course_registration.academic_calendar_id = self.academic_calendar_id
  #        course_registration.student_id = self.student.id
  #        course_registration.student_full_name = self.student_full_name
  #        course_registration.course_id = co.id
  #        course_registration.academic_year = get_academic_year(self.semester, self.student)
  #        course_registration.course_title = co.course_title
  #        course_registration.semester = self.semester
  #        course_registration.year = self.year
  #        course_registration.created_by = self.created_by
  #      end
  #    end
  #  end
  #    CourseRegistration.import! all_courses
  #  end
  # end

  def change_course_registration_status
    if registrar_approval_status == 'approved'
      course_registrations.where(enrollment_status: 'pending').map do |course|
        course.update_columns(enrollment_status: 'enrolled')
      end
    end
  end

  def get_academic_year(semester, student)
    if semester == 1
      Date.current.year
    else
      last_course_registration = CourseRegistration.select(:academic_year).where(student:).where(semester: 1).last
      if last_course_registration.nil?
        # Handle the case where there's no previous course registration
        Date.current.year # or some other default value
      else
        last_course_registration.academic_year
      end
    end
  end

  def assign_section_to_course_registration
    if (registrar_approval_status == 'approved') && section.present?
      course_registrations.where(section_id: nil).map { |course| course.update(section_id:) }
    end
  end
end
