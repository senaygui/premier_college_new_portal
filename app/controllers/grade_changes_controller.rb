class GradeChangesController < ApplicationController
  def index
    @grade_changes = GradeChange.where(student_id: current_student)
  end

  def new
    @grade = StudentGrade.find(params[:grade_id])
    @course = @grade.course
    @program = @course.program
    @department = @program.department
    @grade_change = GradeChange.new
    # Fetch associations
    @student = @grade.student
    @section = @student.section
    @academic_calendar = @student.academic_calendar
    @course_registration = @grade.course_registration
    # @assessment = @student.assessment
  end

  def show
    @grade_change = GradeChange.find(params[:id])
    @grade = @grade_change.student_grade
    @course = @grade.course
    @program = @course.program
    @department = @program.department
    @student = @grade.student
    @section = @student.section
    @academic_calendar = @student.academic_calendar
    @course_registration = @grade.course_registration
  end

  def create
    @grade = StudentGrade.find(params[:grade_change][:student_grade_id])
    @course = @grade.course
    @program = @course.program
    @department = @program.department
    @student = @grade.student
    @section = @student.section
    @academic_calendar = @student.academic_calendar
    @course_registration = @grade.course_registration

    @grade_change = GradeChange.new(grade_change_params)

    # Manually setting associations
    @grade_change.course_id = @course.id
    @grade_change.program_id = @program.id
    @grade_change.department_id = @department.id
    @grade_change.student_id = @student.id
    @grade_change.section_id = @section.id if @section.present?
    # @grade_change.academic_calendar_id = @academic_calendar.id if @academic_calendar.present?
    @grade_change.course_registration_id = @course_registration.id

    if @grade_change.save
      redirect_to root_path, notice: 'Grade change request submitted successfully.'
    else
      flash.now[:alert] = 'There was an error with your submission.'
      render :new
    end
  end

  private

  def grade_change_params
    params.require(:grade_change).permit(:reason, :course_id, :program_id, :department_id, :semester, :year,
                                         :previous_result_total, :previous_letter_grade, :student_grade_id, :assessment_id)
  end
end
