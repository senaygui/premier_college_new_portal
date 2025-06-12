class StudentGrade < ApplicationRecord
  after_create :generate_assessment
  # after_create -> { course_registration.active_no! }

  after_create do
    Course.increment_counter(:f_counter, self) if letter_grade == 'F' || letter_grade == 'f'
  end
  attr_accessor :skip_assessment_total_calc

  after_save :update_subtotal, unless: -> { skip_assessment_total_calc }
  after_commit :generate_grade
  # after_save :add_course_registration
  # after_save :update_grade_report
  validates :student, presence: true
  validates :course, presence: true
  belongs_to :course_registration, optional: true
  belongs_to :student
  belongs_to :course
  belongs_to :department, optional: true
  belongs_to :program, optional: true
  has_many :assessments, dependent: :destroy
  accepts_nested_attributes_for :assessments, reject_if: :all_blank, allow_destroy: true
  has_many :grade_changes
  has_many :makeup_exams
  validates_uniqueness_of :id, scope: %i[student_id course_id]

  def add_course_registration
    unless course_registration.present?
      cr = CourseRegistration.where(student_id: student.id, course_id: course.id).last.id
      update_columns(course_registration_id: cr)
    end
  end

  def generate_assessment
    Rails.logger.info "==> after_create callback is running for StudentGrade #{id}"
    course.assessment_plans.each do |plan|
      Assessment.create! do |assessment|
        assessment.student_grade_id = id
        assessment.course_id = course.id
        assessment.student_id = student.id
        assessment.course_registration_id = course_registration.id
        assessment.assessment_plan_id = plan.id
        assessment.final_exam = plan.final_exam
        assessment.created_by = created_by
        assessment.admin_user_id = AdminUser.all.first.id
      end
    end
  end
  # class StudentGrade < ApplicationRecord
  #  # after_create :generate_assessment
  #  after_create -> { self.course_registration.active_no! }
  #  after_save :add_course_registration # Enable the callback
  #
  #  validates :student, presence: true
  #  validates :course, presence: true
  #  belongs_to :course_registration, optional: true
  #  belongs_to :student
  #  belongs_to :course
  #  belongs_to :department, optional: true
  #  belongs_to :program, optional: true
  #  has_many :grade_changes
  #  has_many :makeup_exams
  #  validates_uniqueness_of :id, scope: [:student_id, :course_id]
  #
  #  def add_course_registration
  #    Rails.logger.debug "add_course_registration called for StudentGrade ID: #{self.id}"
  #    unless self.course_registration.present?
  #      cr = CourseRegistration.where(student_id: self.student.id, course_id: self.course.id).last
  #      if cr.present?
  #        self.update_columns(course_registration_id: cr.id)
  #        Rails.logger.debug "course_registration_id set to #{cr.id} for StudentGrade ID: #{self.id}"
  #      else
  #        Rails.logger.warn "No course registration found for student_id #{self.student.id} and course_id #{self.course.id}"
  #      end
  #    end
  #  end
  #

  # Rest of the model code...

  def assesment_total1
    # assessments.collect { |oi| oi.valid? ? (oi.result) : 0 }.sum
    assessments.sum(:result)
  end

  def self.create_student_grade(crs)
    counter = 0
    crs.each do |cr|
      counter += 1 if cr.student_grade.blank? && MoodleGrade.moodle_grade(cr)
    end
    counter
  end

  def self.online_student_grade(department, year, semester, status)
    ids = Student.where(admission_type: 'online').where(department_id: department).where(year:).where(semester:).select('id')
    StudentGrade.where(student_id: ids).where(department_approval: status.strip).includes(:student).includes(:department)
  end

  def update_subtotal
    update_columns(assesment_total: assessments.sum(:result)) if assessments.any?
  end

  def generate_grade
    return unless assessments.any?

    if course.credit_hour > 0
      if assessments.where(result: nil).empty?
        grade = student.program.grade_systems.last.grades.where('min_row_mark <= ? AND max_row_mark >= ?',
                                                                assesment_total, assesment_total).last

        update_columns(
          letter_grade: grade.letter_grade,
          grade_point: grade.grade_point
        )
      elsif assessments.where(result: nil, final_exam: true).present?
        update_columns(letter_grade: 'I', grade_point: 0)
      elsif assessments.where(result: nil, final_exam: false).present?
        update_columns(letter_grade: 'NG', grade_point: 0)
      end

    elsif course.credit_hour == 0
      if assessments.where(result: nil).empty?
        grade_in_letter = assesment_total > 40 ? 'P' : 'F'
        update_columns(letter_grade: grade_in_letter, grade_point: 0)
      elsif assessments.where(result: nil, final_exam: true).present?
        update_columns(letter_grade: 'NG', grade_point: 0)
      elsif assessments.where(result: nil, final_exam: false).present?
        update_columns(letter_grade: 'I', grade_point: 0)
      end
    end
  end

  # def generate_assessment
  #   course.assessment_plans.each do |plan|
  #     Assessment.create do |assessment|
  #       assessment.course_id = course.id
  #       assessment.student_id = student.id
  #       assessment.student_grade_id = id
  #       assessment.assessment_plan_id = plan.id
  #       assessment.final_exam = plan.final_exam
  #       assessment.created_by = created_by
  #     end
  #   end
  # end

  def moodle_grade
    url = URI('https://lms.premiercollege.edu.et/webservice/rest/server.php')
    moodle = MoodleRb.new('824b4fdd7f79d85eb767106ce969bf57', 'https://lms.premiercollege.edu.et/webservice/rest/server.php')
    lms_student = moodle.users.search(email: "#{student.email}")
    user = lms_student[0]['id']
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Post.new(url)
    form_data = [%w[wstoken 92dac7334a9d4aee7cc3474b81f15c45],
                 %w[wsfunction gradereport_overview_get_course_grades], %w[moodlewsrestformat json], ['userid', "#{user}"]]
    request.set_form form_data, 'multipart/form-data'
    response = https.request(request)
    # puts response.read_body
    results =  JSON.parse(response.read_body)
    course_code = moodle.courses.search("#{course_registration.course.course_code}")
    course = course_code['courses'][0]['id']

    total_grade = results['grades'].map { |h1| h1['rawgrade'] if h1['courseid'] == course }.compact.first
    grade_letter = results['grades'].map { |h1| h1['grade'] if h1['courseid'] == course }.compact.first
    # self.update_columns(grade_in_letter: grade_letter)
    update(assesment_total: total_grade.to_f)
  end

  private

  def update_grade_report
    if course_registration.semester_registration.grade_report.present?
      if student.grade_reports.count == 1
        total_credit_hour = course_registration.semester_registration.course_registrations.where(enrollment_status: 'enrolled').collect do |oi|
          (oi.student_grade.letter_grade != 'I') && (oi.student_grade.letter_grade != 'NG') ? oi.course.credit_hour : 0
        end.sum
        total_grade_point = course_registration.semester_registration.course_registrations.where(enrollment_status: 'enrolled').collect do |oi|
          (oi.student_grade.letter_grade != 'I') && (oi.student_grade.letter_grade != 'NG') ? oi.student_grade.grade_point : 0
        end.sum
        sgpa = total_credit_hour == 0 ? 0 : (total_grade_point / total_credit_hour).round(2)
        cumulative_total_credit_hour = total_credit_hour
        cumulative_total_grade_point = total_grade_point
        cgpa = cumulative_total_credit_hour == 0 ? 0 : (cumulative_total_grade_point / cumulative_total_credit_hour).round(1)
        course_registration.semester_registration.grade_report.update(total_credit_hour:,
                                                                      total_grade_point:, sgpa:, cumulative_total_credit_hour:, cumulative_total_grade_point:, cgpa:)
        if course_registration.semester_registration.course_registrations.joins(:student_grade).pluck(:letter_grade).include?('I').present? || course_registration.semester_registration.course_registrations.joins(:student_grade).pluck(:letter_grade).include?('NG').present?
          academic_status = 'Incomplete'
        else
          academic_status = program.grade_systems.last.academic_statuses.where('min_value <= ?', cgpa).where(
            'max_value >= ?', cgpa
          ).last.status
        end

        if course_registration.semester_registration.grade_report.academic_status != academic_status
          if ((course_registration.semester_registration.grade_report.academic_status == 'Academic Dismissal') || (course_registration.semester_registration.grade_report.academic_status == 'Incomplete')) && ((academic_status != 'Academic Dismissal') || (academic_status != 'Incomplete'))
            if program.program_semester > student.semester
              promoted_semester = student.semester + 1
              student.update_columns(semester: promoted_semester)
            elsif (program.program_semester == student.semester) && (program.program_duration > student.year)
              promoted_year = student.year + 1
              student.update_columns(semester: 1)
              student.update_columns(year: promoted_year)
            end
          end
          course_registration.semester_registration.grade_report.update_columns(academic_status:)
        end
      else
        total_credit_hour = course_registration.semester_registration.course_registrations.where(enrollment_status: 'enrolled').collect do |oi|
          (oi.student_grade.letter_grade != 'I') && (oi.student_grade.letter_grade != 'NG') ? oi.course.credit_hour : 0
        end.sum
        total_grade_point = course_registration.semester_registration.course_registrations.where(enrollment_status: 'enrolled').collect do |oi|
          (oi.student_grade.letter_grade != 'I') && (oi.student_grade.letter_grade != 'NG') ? oi.student_grade.grade_point : 0
        end.sum
        sgpa = total_credit_hour == 0 ? 0 : (total_grade_point / total_credit_hour).round(2)

        cumulative_total_credit_hour = GradeReport.where(student_id:).order('created_at ASC').last.cumulative_total_credit_hour + total_credit_hour
        cumulative_total_grade_point = GradeReport.where(student_id:).order('created_at ASC').last.cumulative_total_grade_point + total_grade_point
        cgpa = (cumulative_total_grade_point / cumulative_total_credit_hour).round(2)

        academic_status = program.grade_systems.last.academic_statuses.where('min_value <= ?', cgpa).where(
          'max_value >= ?', cgpa
        ).last.status

        course_registration.semester_registration.grade_report.update(total_credit_hour:,
                                                                      total_grade_point:, sgpa:, cumulative_total_credit_hour:, cumulative_total_grade_point:, cgpa:)

        if course_registration.semester_registration.course_registrations.joins(:student_grade).pluck(:letter_grade).include?('I').present? || course_registration.semester_registration.course_registrations.joins(:student_grade).pluck(:letter_grade).include?('NG').present?
          academic_status = 'Incomplete'
        else
          academic_status = program.grade_systems.last.academic_statuses.where('min_value <= ?', cgpa).where(
            'max_value >= ?', cgpa
          ).last.status
        end

        if course_registration.semester_registration.grade_report.academic_status != academic_status
          if ((course_registration.semester_registration.grade_report.academic_status == 'Academic Dismissal') || (course_registration.semester_registration.grade_report.academic_status == 'Incomplete')) && ((academic_status != 'Academic Dismissal') || (academic_status != 'Incomplete'))
            if program.program_semester > student.semester
              promoted_semester = student.semester + 1
              student.update_columns(semester: promoted_semester)
            elsif (program.program_semester == student.semester) && (program.program_duration > student.year)
              promoted_year = student.year + 1
              student.update_columns(semester: 1)
              student.update_columns(year: promoted_year)
            end
          end
          course_registration.semester_registration.grade_report.update_columns(academic_status:)
        end
      end
    end
  end
end
