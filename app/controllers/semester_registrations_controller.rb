class SemesterRegistrationsController < ApplicationController
  before_action :set_registration, only: %i[ show edit update destroy ]

  # GET /registrations or /registrations.json
  def index
    @semester_registrations = current_student.semester_registrations.all
  end

  # GET /registrations/1 or /registrations/1.json
  def show
  end

  # GET /registrations/new
  def new
    @semester_registration = SemesterRegistration.new
  end

  # GET /registrations/1/edit
  def edit
    # @course_registrations = semester_registration.course_registrations.where(year: current_student.year, semester: current_student.semester)

   
    #@registration_fee = CollegePayment.where(study_level: @semester_registration.study_level,admission_type: @semester_registration.admission_type).first.registration_fee 
    
    #if current_student.year == 1 && current_student.semester == 1
     # @tution_fee = (@semester_registration.course_registrations.collect { |oi| oi.valid? ? (CollegePayment.where(study_level: @semester_registration.study_level,admission_type: @semester_registration.admission_type).first.tution_per_credit_hr * oi.course.credit_hour) : 0 }.sum) + 2100
    
   # else 
    #  @tution_fee = (@semester_registration.course_registrations.collect { |oi| oi.valid? ? (CollegePayment.where(study_level: @semester_registration.study_level,admission_type: @semester_registration.admission_type).first.tution_per_credit_hr * oi.course.credit_hour) : 0 }.sum)
    #end
    
   # @total = @registration_fee + @tution_fee


    @registration_fee = current_student.get_registration_fee
    @tution_fee =  current_student.get_tuition_fee

  end

  # POST /registrations or /registrations.json
  def create
    @semester_registration = SemesterRegistration.new(semester_registration_params)

    respond_to do |format|
      if @semester_registration.save
        format.html { redirect_to @semester_registration, notice: "semester_registration was successfully created." }
        format.json { render :show, status: :created, location: @semester_registration }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @semester_registration.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /registrations/1 or /registrations/1.json
  def update
    respond_to do |format|
      if @semester_registration.update(semester_registration_params)
        format.html { redirect_to invoice_path(@semester_registration.invoices.last.id), notice: "Registration was successfully updated." }
        format.json { render :show, status: :ok, location: @semester_registration }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @semester_registration.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /registrations/1 or /registrations/1.json
  def destroy
    @semester_registration.destroy
    respond_to do |format|
      format.html { redirect_to semester_registrations_url, notice: "semester_registration was successfully destroyed." }
      format.json { head :no_content }
    end
  end
  
  def download_pdf
    @semester_registration = SemesterRegistration.find(params[:id])
                                                      
    pdf = Prawn::Document.new
  
    # Add the logo at the top center
    logo_path = Rails.root.join('app/assets/images/logo3.jpg')
    pdf.image logo_path, at: [pdf.bounds.width / 2 - 50, pdf.cursor], width: 100
    pdf.move_down 60
  
    pdf.text "Student Registration Information", size: 20, style: :bold, align: :center
    pdf.move_down 20
    pdf.text "Full Name: #{@semester_registration.student_full_name}"
    pdf.text "Student ID: #{@semester_registration.student_id_number}"
    pdf.text "Program: #{@semester_registration.program.program_name}"
    pdf.text "Department: #{@semester_registration.department.department_name}" if @semester_registration.department.present?
    pdf.text "Year: #{@semester_registration.year}"
    pdf.text "Semester: #{@semester_registration.semester}"
    pdf.move_down 20
  
    pdf.text "Course Registrations", size: 18, style: :bold
    pdf.move_down 10
  
    table_data = [["No", "Course Name", "Code", "Credit Hour", "Contact Hour"]]
  
    total_credit_hours = 0
    total_contact_hours = 0
  
    @semester_registration.course_registrations.each_with_index do |registration, index|
      table_data << [
        index + 1,
        registration.course.course_title,
        registration.course.course_code,
        registration.course.credit_hour,
        registration.course.ects
      ]
      total_credit_hours += registration.course.credit_hour
      total_contact_hours += registration.course.ects
    end
  
    pdf.table(table_data, header: true, row_colors: ["F0F0F0", "FFFFFF"], cell_style: { borders: [:top, :bottom] }) do
      row(0).font_style = :bold
      row(0).background_color = "CCCCCC"
    end
  
    pdf.move_down 20
    pdf.text "Total Credit Hours: #{total_credit_hours}", size: 14, style: :bold
    pdf.text "Total Contact Hours: #{total_contact_hours}", size: 14, style: :bold
  
    send_data pdf.render, filename: "semester_registration_#{@semester_registration.id}.pdf", type: 'application/pdf'
   
  end
  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_registration
      @semester_registration = SemesterRegistration.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def semester_registration_params
      params.fetch(:semester_registration, {}).permit(:mode_of_payment)
    end
end
