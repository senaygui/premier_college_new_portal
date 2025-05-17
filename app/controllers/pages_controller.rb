class PagesController < ApplicationController
  before_action :authenticate_student!,
                only: %i[enrollement documents profile dashboard create_semester_registration]
  # layout false, only: [:home]
  def home
    # authenticate_student!
  end

  def admission; end

  def documents; end

  def digital_iteracy_quiz; end

  def requirement; end

  def profile
    @address = current_student.student_address
    @emergency_contact = current_student.emergency_contact
  end

  def dashboard
    @address = current_student.student_address
    @emergency_contact = current_student.emergency_contact
    @invoice = Invoice.find_by(student: current_student, semester: current_student.semester, year: current_student.year)
    @smr = current_student.semester_registrations.where(year: current_student.year,
                                                        semester: current_student.semester).last
    @payment_remaining = current_student.semester_registrations.where('remaining_amount > ?', 0).last if @smr.nil?

    @student_grades = StudentGrade.eager_load(:course_registration)
                                  .where('course_registrations.year=?', current_student.year)
                                  .where('course_registrations.semester=?', current_student.semester)
                                  .where(student: current_student).includes(:course)

    # @verified_makeup_exam = MakeupExam.find_by(student_id: current_student.id, verified: true)
  end

  def enrollement
    @total_course = current_student.get_current_courses.select do |course|
      passed_all_prerequisites?(current_student, course)
    end
    # @total_course = current_student.get_current_courses
    @registration_fee = current_student.get_registration_fee
    @tution_fee = current_student.get_tuition_fee
    # @total = @registration_fee + tution_fee
  end

  def add_enrollement
    @total_course = current_student.get_added_course
    @tution_fee = current_student.get_added_tution_fee
    @semester_registration = current_student.semester_registrations.where(year: current_student.year,
                                                                          semester: current_student.semester).last

    if @semester_registration
      @total_course.each do |course|
        course_registration = CourseRegistration.new(
          semester_registration_id: @semester_registration.id,
          program_id: current_student.program.id,
          department_id: current_student.department.id,
          academic_calendar_id: @semester_registration.academic_calendar_id,
          student_id: current_student.id,
          student_full_name: current_student.full_name,
          course_id: course.course.id,
          academic_year: @semester_registration.academic_calendar.calender_year_in_gc,
          course_title: course.course.course_title,
          semester: @semester_registration.semester,
          year: @semester_registration.year,
          created_by: current_student.id
        )

        course.update(status: :taken) if course_registration.save
      end

      redirect_to dashboard_path, notice: 'Courses were successfully added to your registration.'
    else
      redirect_to dashboard_path, alert: 'No active semester registration found.'
    end
  end

  def create_semester_registration
    mode_of_payment = params[:mode_of_payment]
    registration = if params[:out_of_batch].present?
                     current_student.add_student_registration(mode_of_payment, true)
                   else
                     current_student.add_student_registration(mode_of_payment, false)
                   end
    respond_to do |format|
      if registration.save
        format.html do
          redirect_to invoice_path(registration.invoices.last.id), notice: 'Registration was successfully created.'
        end
        format.json { render :show, status: :ok, location: registration }
      else
        format.html { redirect_to :enrollement_path, alert: 'Something went wrong please try again' }
        format.json { render json: registration.errors, status: :unprocessable_entity }
      end
    end
  end

   private

  def passed_all_prerequisites?(student, course)
    prerequisites = Prerequisite.where(course_id: course.id)

    prerequisites.all? do |prerequisite|
      prerequisite_course = prerequisite.prerequisite
      student_grade = StudentGrade.find_by(student_id: student.id, course_id: prerequisite_course.id)

      # First check if student_grade is nil; if not, then check if the grade is not 'F'
      student_grade.nil? || student_grade.letter_grade != 'F'
    end
  end
end
