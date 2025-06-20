ActiveAdmin.register SemesterRegistration do
  menu parent: 'Student managment'

  permit_params :department_id, :program_id, :section_id, :student_full_name, :student_id_number, :student_id,
                :total_price, :registration_fee, :late_registration_fee, :remaining_amount, :mode_of_payment, :semester, :year, :total_enrolled_course, :academic_calendar_id, :registrar_approval_status, :finance_approval_status, :created_by, :last_updated_by, course_registrations_attributes: %i[id student_id semester_registration_id course_id academic_calendar_id student_full_name enrollment_status course_title department_id program_id section_id year semester created_by updated_by _destroy]

  active_admin_import validate: true,
                      headers_rewrites: { 'student id': :student_id },
                      before_batch_import: lambda { |importer|
                        student_ids = importer.values_at(:student_id)
                        students = Student.where(student_id: student_ids).pluck(:student_id, :id)
                        options = Hash[*students.flatten]
                        importer.batch_replace(:student_id, options)
                      }
  scoped_collection_action :scoped_collection_update, title: 'Batch Action', form: lambda {
                                                                                     {
                                                                                       section_id: Section.all.map do |section|
                                                                                                     [
                                                                                                       section.section_full_name, section.id
                                                                                                     ]
                                                                                                   end,
                                                                                       registrar_approval_status: %w[pending approved denied
                                                                                                                     incomplete],
                                                                                       mode_of_payment: ['Monthly Payment', 'Half Semester Payment',
                                                                                                         'Full Semester Payment']
                                                                                     }
                                                                                   }

                                                      member_action :download_pdf, method: :get do
                                                        @semester_registration = SemesterRegistration.find(params[:id])

                                                        pdf = Prawn::Document.new

                                                        # Add the logo at the top center
                                                        logo_path = Rails.root.join('app/assets/images/logo3.jpg')
                                                        pdf.image logo_path,
                                                                  at: [pdf.bounds.width / 2 - 50, pdf.cursor], width: 100
                                                        pdf.move_down 60

                                                        pdf.text 'Student Registration Information', size: 20,
                                                                                                     style: :bold, align: :center
                                                        pdf.move_down 20
                                                        pdf.text "Full Name: #{@semester_registration.student_full_name}"
                                                        pdf.text "Student ID: #{@semester_registration.student_id_number}"
                                                        pdf.text "Program: #{@semester_registration.program.program_name}"
                                                        if @semester_registration.department.present?
                                                          pdf.text "Department: #{@semester_registration.department.department_name}"
                                                        end
                                                        pdf.text "Year: #{@semester_registration.year}"
                                                        pdf.text "Semester: #{@semester_registration.semester}"
                                                        pdf.move_down 20

                                                        pdf.text 'Course Registrations', size: 18, style: :bold
                                                        pdf.move_down 10

                                                        table_data = [['No', 'Course Name', 'Code', 'Credit Hour',
                                                                       'Contact Hour']]

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

                                                        pdf.table(table_data, header: true,
                                                                              row_colors: %w[F0F0F0 FFFFFF], cell_style: { borders: %i[top bottom] }) do
                                                          row(0).font_style = :bold
                                                          row(0).background_color = 'CCCCCC'
                                                        end

                                                        pdf.move_down 20
                                                        pdf.text "Total Credit Hours: #{total_credit_hours}", size: 14,
                                                                                                              style: :bold
                                                        pdf.text "Total Contact Hours: #{total_contact_hours}",
                                                                 size: 14, style: :bold

                                                        send_data pdf.render,
                                                                  filename: "semester_registration_#{@semester_registration.id}.pdf", type: 'application/pdf'
                                                      end

                                                      action_item :download_pdf, only: :show do
                                                        link_to 'Print_registration_slip',
                                                                download_pdf_admin_semester_registration_path(semester_registration), class: 'button'
                                                      end

  batch_action 'Deny finance status for', method: :put, confirm: 'Are you sure?' do |ids|
    smr = SemesterRegistration.where(id: ids)

    result = smr.update_all(finance_approval_status: 'denied')
    if result
      smr.each do |smr|
        smr.denied_enrollment_status
      end
      redirect_to admin_semester_registrations_path,
                  notice: "#{'student'.pluralize(ids.size)} finance verification status denied"
    end
  end
  batch_action 'Approve finance status for', method: :put, confirm: 'Are you sure?' do |ids|
    smr = SemesterRegistration.where(id: ids)
    smr.update_all(finance_approval_status: 'approved')
    smr.each do |smr|
      smr.approve_enrollment_status
    end
    redirect_to admin_semester_registrations_path,
                notice: "#{'student'.pluralize(ids.size)} finance verification status Approved"
  end

  batch_action 'Deny registrar status for', method: :put, confirm: 'Are you sure?' do |ids|
    smr = SemesterRegistration.where(id: ids)
    smr.update_all(registrar_approval_status: 'denied')
    smr.each do |smr|
      smr.denied_enrollment_status
    end
    redirect_to admin_semester_registrations_path,
                notice: "#{'student'.pluralize(ids.size)} registrar verification status denied"
  end
  batch_action 'Approve registrar status for', method: :put, confirm: 'Are you sure?' do |ids|
    smr = SemesterRegistration.where(id: ids)
    smr.update_all(registrar_approval_status: 'approved')
    smr.each do |smr|
      smr.approve_enrollment_status
    end
    SemesterRegistration.where(id: ids).update(registrar_approval_status: 'approved')
    redirect_to admin_semester_registrations_path,
                notice: "#{'student'.pluralize(ids.size)} registrar verification status Approved"
  end

  csv do
    column 'username' do |username|
      username.student.student_id
    end
    column 'password' do |pass|
      pass.student.student_password
    end
    column 'firstname' do |fn|
      fn.student.first_name
    end
    column 'lastname' do |ln|
      ln.student.last_name
    end
    column 'email' do |e|
      e.student.email
    end
    column 'course1' do |e|
      e.course_registrations[0].course.course_code if e.course_registrations[0]
    end
    column 'role1' do |_e|
      'student'
    end
    column 'course2' do |e|
      e.course_registrations[1].course.course_code if e.course_registrations[1]
    end
    column 'role2' do |_e|
      'student'
    end
    column 'course3' do |e|
      e.course_registrations[2].course.course_code if e.course_registrations[2]
    end
    column 'role3' do |_e|
      'student'
    end
    column 'course4' do |e|
      e.course_registrations[3].course.course_code if e.course_registrations[3]
    end
    column 'role4' do |_e|
      'student'
    end
    column 'course5' do |e|
      e.course_registrations[4].course.course_code if e.course_registrations[4]
    end
    column 'role5' do |_e|
      'student'
    end
    column 'course6' do |e|
      e.course_registrations[5].course.course_code if e.course_registrations[5]
    end
    column 'role6' do |_e|
      'student'
    end
  end
  # controller do
  #   def create
  #     super do |format|
  #     if @CollegePayment.save
  #       format.html { redirect_to edit_admin_semester_registration_path(@semester_registration), notice: 'student registration created successfully.' }
  #       format.json { render :show, status: :created, location: @semester_registration }
  #     else
  #       format.html { render :new }
  #       format.json { render json: @semester_registration.errors, status: :unprocessable_entity }
  #     end
  #   end
  #     # super
  #   end
  # end

  # controller do
  #   def scoped_collection
  #     # super.where(academic_calendar_id: AcademicCalendar.where("starting_date <= ? AND ending_date >= ?",Time.zone.now, Time.zone.now).order("created_at DESC").pluck(:id).first).where(semester: Semester.where("starting_date <= ? AND ending_date >= ?",Time.zone.now, Time.zone.now).order("created_at DESC").pluck(:semester).first)
  #   end
  # end
  member_action :generate_grade_report, method: :put do
    @semester_registration = SemesterRegistration.find(params[:id])
    @semester_registration.generate_grade_report
    redirect_back(fallback_location: admin_student_grade_path)
  end

  batch_action 'Generate grade report for', if: proc {
                                                  current_admin_user.role == 'registrar head' || current_admin_user.role == 'admin'
                                                }, method: :put, confirm: 'Are you sure?' do |ids|
    SemesterRegistration.find(ids).each do |sm|
      sm.generate_grade_report
    end
    redirect_to collection_path, notice: 'Grade Report Is Generated Successfully'
  end
  action_item :update, only: :show do
    link_to 'generate grade report', generate_grade_report_admin_semester_registration_path(semester_registration.id),
            method: :put, data: { confirm: 'Are you sure?' }
  end

  index do
    selectable_column
    column 'Full Name', sortable: 'students.first_name' do |n|
      [n.student.first_name, n.student.middle_name, n.student.last_name].compact.join(' ')
    end
    column 'Program' do |n|
      n.program.program_name
    end
    # column :study_level
    column 'Academic Year', sortable: true do |n|
      link_to n.academic_calendar.calender_year, admin_academic_calendar_path(n.academic_calendar)
    end
    column :semester
    column :year
    column 'Finance status', sortable: true do |c|
      status_tag c.finance_approval_status
    end
    column 'Register status', sortable: true do |c|
      status_tag c.registrar_approval_status
    end
    column 'Section', sortable: true do |n|
      link_to n.section.section_full_name, admin_program_section_path(n.section) if n.section.present?
    end
    # column :mode_of_payment
    column 'Created At', sortable: true do |c|
      c.created_at.strftime('%b %d, %Y')
    end
    actions
  end

  filter :student_id_number
  filter :student_full_name
  filter :department_id, as: :search_select_filter, url: proc { admin_departments_path },
                         fields: %i[department_name id], display_name: 'department_name', minimum_input_length: 2,
                         order_by: 'id_asc'
  filter :academic_calendar_id, as: :search_select_filter, url: proc { admin_academic_calendars_path },
                                fields: %i[calender_year id], display_name: 'calender_year', minimum_input_length: 2,
                                order_by: 'id_asc'
  filter :mode_of_payment
  filter :section_id, as: :search_select_filter, url: proc { admin_program_sections_path },
                      fields: %i[section_full_name id], display_name: 'section_full_name', minimum_input_length: 2,
                      order_by: 'id_asc'
  filter :semester
  filter :year
  filter :admission_type
  filter :study_level
  filter :program_name
  filter :registrar_approval_status
  filter :finance_approval_status
  filter :last_updated_by
  filter :created_by
  filter :created_at
  filter :updated_at

  scope :recently_added
  scope :undergraduate
  scope :graduate
  scope :online, if: proc { current_admin_user.role == 'admin' }
  scope :regular, if: proc { current_admin_user.role == 'admin' }
  scope :extention, if: proc { current_admin_user.role == 'admin' }
  scope :distance, if: proc { current_admin_user.role == 'admin' }
  form do |f|
    f.semantic_errors
    unless f.object.new_record?
      panel 'Student Information' do
        attributes_table_for semester_registration do
          # row "photo" do |pt|
          #   span image_tag(pt.student.photo, size: '150x150', class: "img-corner")
          # end
          row 'full name', sortable: true do |n|
            n.student_full_name
          end
          row 'Student ID' do |si|
            si.student_id_number
          end
          row 'Program' do |pr|
            link_to pr.student.program.program_name, admin_program_path(pr.student.program.id)
          end
          row 'Department' do |si|
            link_to si.department.department_name, admin_department_path(si.department.id)
          end
          row :admission_type do |si|
            si.admission_type
          end
          row :study_level do |si|
            si.study_level
          end
          row :year do |si|
            si.year
          end
          row :semester do |si|
            si.semester
          end
          # row :department
          # row :admission_type
          # row :study_level
          # row :year
        end
      end
      f.object.course_registrations << CourseRegistration.new if f.object.course_registrations.empty?
      panel 'Course Registration' do
        f.has_many :course_registrations, heading: ' ', remote: true, allow_destroy: true, new_record: true do |a|
          a.input :course_id, as: :select,
                              collection: Course.where(program: semester_registration.program).pluck(:course_title, :id)
          a.input :section_id, as: :search_select, url: admin_program_sections_path,
                               fields: %i[section_full_name id], display_name: 'section_full_name', minimum_input_length: 2,
                               order_by: 'id_asc'
          a.input :student_id, as: :hidden, input_html: { value: semester_registration.student.id }
          a.input :academic_calendar_id, as: :hidden,
                                         input_html: { value: semester_registration.academic_calendar_id }
          a.input :student_full_name, as: :hidden, input_html: { value: semester_registration.student_full_name }
          a.input :program_id, as: :hidden, input_html: { value: semester_registration.program_id }
          a.input :department_id, as: :hidden, input_html: { value: semester_registration.department_id }
          a.input :semester, as: :hidden, input_html: { value: semester_registration.semester }
          a.input :year, as: :hidden, input_html: { value: semester_registration.year }
          # a.input :course_title, as: :hidden, :input_html => { :value => semester_registration.course_title}
          if a.object.new_record?
            a.input :created_by, as: :hidden, input_html: { value: current_admin_user.name.full }
          else
            a.input :updated_by, as: :hidden, input_html: { value: current_admin_user.name.full }
          end
          a.label :_destroy
        end
      end
    end
    f.inputs 'Student registration information' do
      f.input :student_id, as: :search_select, url: admin_students_path,
                           fields: %i[student_id id], display_name: 'student_id', minimum_input_length: 2,
                           order_by: 'id_asc'
      f.input :program_id, as: :search_select, url: admin_programs_path,
                           fields: %i[program_name id], display_name: 'program_name', minimum_input_length: 2,
                           order_by: 'id_asc'
      f.input :department_id, as: :search_select, url: admin_departments_path,
                              fields: %i[department_name id], display_name: 'department_name', minimum_input_length: 2,
                              order_by: 'id_asc'
      f.input :academic_calendar_id, as: :search_select, url: admin_academic_calendars_path,
                                     fields: %i[calender_year id], display_name: 'calender_year', minimum_input_length: 2,
                                     order_by: 'id_asc'

      f.input :semester, as: :select, collection: [1, 2, 3, 4], include_blank: false
      f.input :year, as: :select, collection: [1, 2, 3, 4, 5, 6, 7], include_blank: false
      f.input :section_id, as: :search_select, url: admin_program_sections_path,
                           fields: %i[section_full_name id], display_name: 'section_full_name', minimum_input_length: 2,
                           order_by: 'id_asc'
      f.input :mode_of_payment, as: :select,
                                collection: ['Monthly Payment', 'Half Semester Payment', 'Full Semester Payment']
      # f.input :remark
      # if f.object.course_registrations.empty?
      #   f.object.course_registrations << CourseRegistration.new
      # end
      # panel "course registrations information" do
      #   f.input :curriculums, :as => :check_boxes, :collection => registration.student.program.curriculums.where(year: registration.student.year, semester: registration.student.semester).course_id
      # end
      if f.object.new_record?
        f.input :created_by, as: :hidden, input_html: { value: current_admin_user.name.full }
      else
        f.input :last_updated_by, as: :hidden, input_html: { value: current_admin_user.name.full }
        f.input :registrar_approval_status, as: :select, collection: %w[pending approved deined]
      end
    end
    f.actions
  end

  show title: proc { |student| student.student.name.full } do
    panel 'Student registration information' do
      attributes_table_for semester_registration do
        row 'full name', sortable: true do |n|
          link_to n.student.name.full, admin_student_path(n.student.id)
        end
        row 'Student ID' do |si|
          si.student.student_id
        end
        row 'Program' do |pr|
          link_to pr.program.program_name, admin_program_path(pr.program.id)
        end
        row :admission_type
        row :study_level
        row 'Department' do |si|
          link_to si.department.department_name, admin_department_path(si.department.id) if si.department.present?
        end
        row 'Section' do |si|
          si.section.section_short_name if si.section.present?
        end
        row 'Academic year' do |si|
          si.academic_calendar.calender_year
        end

        row :year
        row :semester
        row :mode_of_payment
        if semester_registration.registration_fee > 0
          number_row :registration_fee, as: :currency, unit: 'ETB', format: '%n %u', delimiter: ',',
                                        precision: 2
        end
        if semester_registration.late_registration_fee > 0
          number_row :late_registration_fee, as: :currency, unit: 'ETB', format: '%n %u', delimiter: ',',
                                             precision: 2
        end
        number_row :remaining_amount, as: :currency, unit: 'ETB', format: '%n %u', delimiter: ',', precision: 2
        number_row :total_price, as: :currency, unit: 'ETB', format: '%n %u', delimiter: ',', precision: 2

        row :created_by
        row :last_updated_by
        row :created_at
        row :updated_at
      end
    end
    panel 'Course Registration' do
      table_for semester_registration.course_registrations do
        column 'Course title' do |pr|
          link_to pr.course_title, admin_course_path(pr.course)
        end
        column 'Course code' do |pr|
          pr.course.course_code
        end
        column 'Course module' do |pr|
          link_to pr.course.course_module.module_code, admin_course_module_path(pr.course.course_module.id)
        end
        column 'Credit hour' do |pr|
          pr.course.credit_hour
        end
        column 'Grade Point' do |pr|
          pr.course.ects
        end
        column :enrollment_status
        column 'Section' do |si|
          si.section.section_short_name if si.section.present?
        end
        column 'Semester' do |se|
          se.course.semester
        end
        column 'Year' do |ye|
          ye.course.year
        end
      end
    end
  end
end
