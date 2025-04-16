class GradeChange < ApplicationRecord
   after_save :current_grade

    # #validations
    # validates :semester, :presence => true
    # validates :previous_result_total, :presence => true
    # validates :previous_letter_grade, :presence => true
    # validates :reason, :presence => true
  # #associations
    belongs_to :course
    belongs_to :program
    belongs_to :department
    belongs_to :section
    belongs_to :academic_calendar, optional: true
    # belongs_to :course_section, optional: true
    belongs_to :student
    belongs_to :course_registration
    belongs_to :student_grade
    belongs_to :assessment, optional: true
    belongs_to :student_grade

    validates :reason, presence: true
    validates :course_id, presence: true
    validates :program_id, presence: true
    validates :department_id, presence: true
    validates :semester, presence: true
    validates :year, presence: true
    validates :previous_result_total, presence: true
    validates :previous_letter_grade, presence: true

    private

      def current_grade
         if (department_approval == 'approved') && (registrar_approval == 'approved') && (dean_approval == 'approved') && (instructor_approval == 'approved') && (academic_affair_approval == 'approved')
           assessment.update(result: add_mark) if assessment.present?
           student_grade.update_columns(assesment_total: add_mark)
           update_columns(current_result_total: student_grade.assesment_total)
           update_columns(current_letter_grade: student_grade.letter_grade)
         end
      end
end
