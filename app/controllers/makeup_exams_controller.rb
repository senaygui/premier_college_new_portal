class MakeupExamsController < ApplicationController
  before_action :authenticate_student!

  def index
    @makeup_exams = MakeupExam.where(student: current_student).order(created_at: :desc)
  end

  def show
    @makeup_exam = MakeupExam.find(params[:id])
  end

  def new
    @makeup_exam = MakeupExam.new
    @courses = CourseRegistration
               .where(student: current_student, enrollment_status: 'enrolled', semester: current_student.semester, year: current_student.year)
               .joins(:student_grade)
               .where(student_grades: { letter_grade: %w[I NG] })
               .includes(:course)
  end

  def create
    @makeup_exam = MakeupExam.new(makeup_exam_params)
    @makeup_exam.student = current_student
    @makeup_exam.academic_calendar = current_student.academic_calendar
    @makeup_exam.year ||= current_student.year
    @makeup_exam.semester ||= current_student.semester
    @makeup_exam.created_by = current_student.first_name

    if params[:makeup_exam][:course_registration_id].present?
      course_registration = CourseRegistration.find(params[:makeup_exam][:course_registration_id])
      course = course_registration.course

      @makeup_exam.course_id = course.id
      @makeup_exam.program_id = course.program_id
      @makeup_exam.department_id = course.program.department_id
      @makeup_exam.course_registration_id = course_registration.id
      student_grade = StudentGrade.find_by(student: current_student, course_id: course.id)
      @makeup_exam.student_grade_id = student_grade.id if student_grade
      @makeup_exam.previous_result_total = student_grade.assesment_total if student_grade
      @makeup_exam.previous_letter_grade = student_grade.letter_grade if student_grade
    else
      flash[:alert] = 'Course selection is required.'
      @courses = CourseRegistration
                 .where(student: current_student, enrollment_status: 'enrolled', semester: current_student.semester)
                 .joins(:student_grade)
                 .where(student_grades: { letter_grade: %w[I NG] })
                 .includes(:course)
      render :new and return
    end

    if @makeup_exam.save
      redirect_to edit_other_payment_path(OtherPayment.where(payable_type: 'MakeupExam').where(payable_id: @makeup_exam).last),
                  notice: 'Makeup exam request submitted successfully. Please proceed to payment.'
    else
      @courses = CourseRegistration
                 .where(student: current_student, enrollment_status: 'enrolled', semester: current_student.semester)
                 .joins(:student_grade)
                 .where(student_grades: { letter_grade: %w[I NG] })
                 .includes(:course)
      render :new
    end
  end

  def payment
    @makeup_exam = MakeupExam.find(params[:id])
    study_level = current_student.study_level.strip.downcase
    admission_type = current_student.admission_type.strip.downcase
    @college_payment = CollegePayment.where(
      'LOWER(TRIM(study_level)) = ? AND LOWER(TRIM(admission_type)) = ? ',
      study_level,
      admission_type
    ).first
  end

  def verify
    @makeup_exam = MakeupExam.find(params[:id])
    @makeup_exam.update(verified: true)
    create_payment(@makeup_exam)
  end

  def update
    @makeup_exam = MakeupExam.find(params[:id])
    if @makeup_exam.update(makeup_exam_params)
      redirect_to root_path, notice: 'Receipt uploaded successfully.'
    else
      render :payment, status: :unprocessable_entity
    end
  end

  private

  def makeup_exam_params
    params.require(:makeup_exam).permit(:course_registration_id, :reason, :year, :semester, :receipt)
  end

  def create_payment(makeup_exam)
    payment = Payment.new(
      program_id: makeup_exam.program_id,
      student_nationality: current_student.nationality,
      total_fee: makeup_exam.academic_calendar.makeup_exam_fee,
      registration_fee: 0,
      late_registration_fee: 0,
      starting_penalty_fee: 0,
      daily_penalty_fee: 0,
      makeup_exam_fee: makeup_exam.academic_calendar.makeup_exam_fee,
      add_drop: 0,
      tution_per_credit_hr: 0,
      readmission: 0,
      reissuance_of_grade_report: 0,
      student_copy: 0,
      additional_student_copy: 0,
      tempo: 0,
      original_certificate: 0,
      original_certificate_replacement: 0,
      tempo_replacement: 0,
      letter: 0,
      student_id_card: 0,
      student_id_card_replacement: 0,
      name_change: 0,
      transfer_fee: 0,
      other: 0,
      created_by: current_student.first_name,
      last_updated_by: current_student.first_name
    )
    if payment.save
      redirect_to new_payment_path(payment), notice: 'Please complete the payment for your makeup exam.'
    else
      redirect_to root_path, alert: 'There was an issue creating the payment. Please try again.'
    end
  end
end
