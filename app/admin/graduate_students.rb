ActiveAdmin.register Student, as: 'GraduateStudent' do
  menu parent: 'Student managment'

  controller do
    def update_resource(object, attributes)
      update_method = attributes.first[:password].present? ? :update : :update_without_password
      object.send(update_method, *attributes)
    end

    def scoped_collection
      super.where(graduation_status: 'approved') # adjust 'status' if the column is named differently
    end
  end

  def scoped_collection
    super.includes(:school_or_university_information, :curriculum)
  end

  csv do
    # column("No") { |student| student.id }
    column('Id Number', &:student_id)
    column('First Name', &:first_name)
    column('Middle Name', &:middle_name)
    column('Last Name', &:last_name)
    column('Gender', &:gender)
    column('Citizenship', &:nationality)
    column('Date Of Birth', &:date_of_birth)

    column('Grade 10 result') { |student| student.school_or_university_information&.grade_10_result || 'N/A'  }
    column('Grade 10 year') { |student| student.school_or_university_information&.grade_10_exam_taken_year || 'N/A' }
    column('Grade 12 result') { |student| student.school_or_university_information&.grade_12_exam_result || 'N/A' }
    column('Grade 12 year') { |student| student.school_or_university_information&.grade_12_exam_taken_year || 'N/A' }

    # column("Letter of Equivalence") { |student| student.school_or_university_information&.equivalence_letter } # Adjust this column based on your actual field name

    column('TVET/12+2 Program Attend') do |student|
      student.school_or_university_information&.college_or_university || 'N/A'
    end
    column('Level (L3, L4)', &:study_level) # Assuming study_level is Level (L3, L4)
    # column("Coc ID") { |student| student.school_or_university_information&.coc_id } # Adjust based on your actual field name
    column('Coc Attended Date') { |student| student.school_or_university_information&.coc_attendance_date || 'N/A' }
    # Adjust based on your actual field name
    column('Degree Attended') do |student|
          student.school_or_university_information&.college_or_university || 'N/A'
    end
    # Adjust based on your actual field name
    column('Total Credit Hour') do |student|
      Curriculum.where(curriculum_version: student.curriculum_version).last&.total_credit_hour
    end
    column('GPA') { |student| student.grade_reports.sum(:cgpa) || 'N/A' }
  end

  index do
    selectable_column
    column :student_id
    column 'Full Name', sortable: true do |n|
      "#{n.first_name.upcase} #{n.middle_name.upcase} #{n.last_name.upcase}"
    end
    column 'Department', sortable: true do |d|
      link_to d.program.department.department_name, [:admin, d.program.department] if d.program.present?
    end
    column 'Program', sortable: true do |d|
      if d.program.present?
        link_to d.program.program_name, [:admin, d.program]
      else
        link_to 'Please add program type', edit_admin_student_path(d)
      end
    end
    column :study_level do |level|
      level.study_level.capitalize
    end
    column :admission_type do |type|
      type.admission_type.capitalize
    end
    column :batch
    column :graduation_status

    column 'Admission', sortable: true do |c|
      c.created_at.strftime('%b %d, %Y')
    end
    actions
  end

  filter :student_id, label: 'Student ID'
  filter :first_name
  filter :last_name
  filter :middle_name
  filter :gender
  filter :program_id, as: :search_select_filter, url: proc { admin_programs_path },
                      fields: %i[program_name id], display_name: 'program_name', minimum_input_length: 2,
                      order_by: 'id_asc'
  filter :study_level, as: :select, collection: %w[undergraduate graduate]
  filter :admission_type, as: :select, collection: %w[online regular extention distance]
  filter :department_id, as: :search_select_filter, url: proc { admin_departments_path },
                         fields: %i[department_name id], display_name: 'department_name', minimum_input_length: 2,
                         order_by: 'id_asc'
  filter :year
  filter :semester
  filter :batch
  filter :current_occupation
  filter :nationality
  filter :curriculum_version
  filter :account_verification_status, as: :select, collection: %w[pending approved denied incomplete]
  filter :document_verification_status, as: :select, collection: %w[pending approved denied incomplete]
  filter :entrance_exam_result_status
  filter :account_status, as: :select, collection: %w[active suspended]
  filter :graduation_status
  filter :sponsorship_status
  filter :created_by
  filter :last_updated_by
  filter :created_at
  filter :updated_at

  # TODO: color label scopes
  scope :sponsored_students do |students|
    students.where(sponsorship_status: 'true')
  end

  scope :undergraduate
  scope :graduate

  scope :online
  scope :regular
  scope :extention
  scope :distance

  # action_item :edit, only: :show, priority: 0 do
  #   link_to 'Approve Student', generate_student_copy(student.id)
  # end
  action_item :edit, only: :show, priority: 0 do
    link_to 'Student Copy', student_copy_path(graduate_student, format: :pdf)
  end
  show title: proc { |graduate_student|
    truncate("#{graduate_student.first_name.upcase} #{graduate_student.middle_name.upcase} #{graduate_student.last_name.upcase}",
             length: 50)
  } do
    tabs do
      tab 'student General information' do
        columns do
          column do
            panel 'Student Main information' do
              attributes_table_for graduate_student do
                row 'photo' do |pt|
                  span image_tag(pt.photo, size: '150x150', class: 'img-corner') if pt.photo.attached?
                end
                row 'full name', sortable: true do |n|
                  "#{n.first_name.upcase} #{n.middle_name.upcase} #{n.last_name.upcase}"
                end
                row 'Student ID' do |si|
                  si.student_id
                end
                row 'Program' do |pr|
                  link_to pr.program.program_name, admin_program_path(pr.program.id)
                end
                row :curriculum_version
                row :payment_version
                row 'Department' do |pr|
                  if pr.department.present?
                    link_to(pr.department.department_name,
                            admin_department_path(pr.department.id))
                  end
                end
                row :admission_type
                row :study_level
                row 'Academic year' do |si|
                  if si.academic_calendar.present?
                    link_to(si.academic_calendar.calender_year_in_gc,
                            admin_academic_calendar_path(si.academic_calendar))
                  end
                end
                row :year
                row :semester
                row :batch
                row :account_verification_status do |s|
                  status_tag s.account_verification_status
                end
                row :entrance_exam_result_status
                row 'admission Date' do |d|
                  d.created_at.strftime('%b %d, %Y')
                end
                row :student_id_taken_status
                row :old_id_number

                # row :graduation_status
              end
            end
          end
          column do
            panel 'Basic information' do
              attributes_table_for graduate_student do
                row :email
                row :gender
                row :date_of_birth, sortable: true do |c|
                  c.date_of_birth.strftime('%b %d, %Y')
                end
                row :nationality
                row :place_of_birth
                row :marital_status
                row :current_occupation
                row :student_password
              end
            end
            panel 'Account status information' do
              attributes_table_for graduate_student do
                row :account_verification_status do |s|
                  status_tag s.account_verification_status
                end
                row :document_verification_status do |s|
                  status_tag s.document_verification_status
                end
                row :account_status do |s|
                  status_tag s.account_status
                end
                row :sign_in_count, default: 0, null: false
                row :current_sign_in_at
                row :last_sign_in_at
                row :current_sign_in_ip
                row :last_sign_in_ip
                row :created_by
                row :last_updated_by
                row :created_at
                row :updated_at
              end
            end
          end
        end
      end
      tab 'Student Documents ' do
        columns do
          column do
            panel 'High School Information' do
              attributes_table_for graduate_student.school_or_university_information do
                row :last_attended_high_school
                row :school_address
                row :grade_10_result
                row :grade_10_exam_taken_year
                row :grade_12_exam_result
                row :grade_12_exam_taken_year
              end
            end
          end
          column do
            panel 'University/College Information' do
              attributes_table_for graduate_student.school_or_university_information do
                row :college_or_university
                row :phone_number
                row :address
                row :field_of_specialization
                row :level
                row :coc_attendance_date
                row :cgpa
              end
            end
          end
        end
        columns do
          column do
            panel 'Highschool Transcript' do
              if graduate_student.highschool_transcript.attached?
                if graduate_student.highschool_transcript.variable?
                  div class: 'preview-card text-center' do
                    span link_to image_tag(graduate_student.highschool_transcript, size: '200x270'),
                                 graduate_student.highschool_transcript
                  end
                elsif graduate_student.highschool_transcript.previewable?
                  div class: 'preview-card text-center' do
                    span link_to 'view document',
                                 rails_blob_path(graduate_student.highschool_transcript, disposition: 'preview')
                    # span link_to image_tag(student.highschool_transcript.preview(resize: '200x200')), student.highschool_transcript
                  end
                else
                  # span link_to "view document", student.highschool_transcript.service_url
                  span link_to 'view document',
                               rails_blob_path(graduate_student.highschool_transcript, disposition: 'preview')
                end
              else
                h3 class: 'text-center no-recent-data' do
                  'Document Not Uploaded Yet'
                end
              end
            end
            panel 'TVET/Diploma Certificate' do
              if graduate_student.diploma_certificate.attached?
                if graduate_student.diploma_certificate.variable?
                  div class: 'preview-card text-center' do
                    span link_to image_tag(graduate_student.diploma_certificate, size: '200x270'),
                                 graduate_student.diploma_certificate
                  end
                elsif graduate_student.diploma_certificate.previewable?
                  div class: 'preview-card text-center' do
                    span link_to 'view document',
                                 rails_blob_path(graduate_student.diploma_certificate, disposition: 'preview')
                    # span link_to image_tag(student.diploma_certificate.preview(resize: '200x200')), student.diploma_certificate
                  end
                else
                  span link_to 'view document',
                               rails_blob_path(graduate_student.diploma_certificate, disposition: 'preview')
                end
              else
                h3 class: 'text-center no-recent-data' do
                  'Document Not Uploaded Yet'
                end
              end
            end
          end
          column do
            panel 'Grade 10 Matric Certificate' do
              if graduate_student.grade_10_matric.attached?
                if graduate_student.grade_10_matric.variable?
                  div class: 'preview-card text-center' do
                    span link_to image_tag(graduate_student.grade_10_matric, size: '200x270'),
                                 graduate_student.grade_10_matric
                  end
                elsif graduate_student.grade_10_matric.previewable?
                  div class: 'preview-card text-center' do
                    span link_to 'view document',
                                 rails_blob_path(graduate_student.grade_10_matric, disposition: 'preview')
                    # span link_to image_tag(student.grade_10_matric.preview(resize: '200x200')), student.grade_10_matric
                  end
                else
                  span link_to 'view document',
                               rails_blob_path(graduate_student.grade_10_matric, disposition: 'preview')
                end
              else
                h3 class: 'text-center no-recent-data' do
                  'Document Not Uploaded Yet'
                end
              end
            end
            panel 'Certificate Of Competency(COC)' do
              if graduate_student.coc.attached?
                if graduate_student.coc.variable?
                  div class: 'preview-card text-center' do
                    span link_to image_tag(graduate_student.coc, size: '200x270'), graduate_student.coc
                  end
                elsif graduate_student.coc.previewable?
                  div class: 'preview-card text-center' do
                    span link_to 'view document', rails_blob_path(graduate_student.coc, disposition: 'preview')
                    # span link_to image_tag(student.coc.preview(resize: '200x200')), student.coc
                  end
                else
                  span link_to 'view document', rails_blob_path(graduate_student.coc, disposition: 'preview')
                end
              else
                h3 class: 'text-center no-recent-data' do
                  'Document Not Uploaded Yet'
                end
              end
            end
          end
          column do
            panel 'Grade 12 Matric Certificate' do
              if graduate_student.grade_12_matric.attached?
                if graduate_student.grade_12_matric.variable?
                  div class: 'preview-card text-center' do
                    span link_to image_tag(graduate_student.grade_12_matric, size: '200x270'),
                                 graduate_student.grade_12_matric
                  end
                elsif graduate_student.grade_12_matric.previewable?
                  div class: 'preview-card text-center' do
                    span link_to 'view document',
                                 rails_blob_path(graduate_student.grade_12_matric, disposition: 'preview')
                    # span link_to image_tag(student.grade_12_matric.preview(resize: '200x200')), student.grade_12_matric
                  end
                else
                  span link_to 'view document',
                               rails_blob_path(graduate_student.grade_12_matric, disposition: 'preview')
                end
              else
                h3 class: 'text-center no-recent-data' do
                  'Document Not Uploaded Yet'
                end
              end
            end
            panel 'Undergraduate Degree Transcript' do
              if graduate_student.undergraduate_transcript.attached?
                if graduate_student.undergraduate_transcript.variable?
                  div class: 'preview-card text-center' do
                    span link_to image_tag(graduate_student.undergraduate_transcript, size: '200x270'),
                                 graduate_student.undergraduate_transcript
                  end
                elsif graduate_student.undergraduate_transcript.previewable?
                  div class: 'preview-card text-center' do
                    span link_to 'view document',
                                 rails_blob_path(graduate_student.undergraduate_transcript, disposition: 'preview')
                    # span link_to image_tag(student.undergraduate_transcript.preview(resize: '200x200')), student.undergraduate_transcript
                  end
                else
                  span link_to 'view document',
                               rails_blob_path(graduate_student.undergraduate_transcript, disposition: 'preview')
                end
              else
                h3 class: 'text-center no-recent-data' do
                  'Document Not Uploaded Yet'
                end
              end
            end
          end
          column do
            panel 'Undergraduate Degree Certificate' do
              if graduate_student.degree_certificate.attached?
                if graduate_student.degree_certificate.variable?
                  div class: 'preview-card text-center' do
                    span link_to image_tag(graduate_student.degree_certificate, size: '200x270'),
                                 graduate_student.degree_certificate
                  end
                elsif graduate_student.degree_certificate.previewable?
                  div class: 'preview-card text-center' do
                    span link_to 'view document',
                                 rails_blob_path(graduate_student.degree_certificate, disposition: 'preview')
                    # span link_to image_tag(student.degree_certificate.preview(resize: '200x200')), student.degree_certificate
                  end
                else
                  span link_to 'view document',
                               rails_blob_path(graduate_student.degree_certificate, disposition: 'preview')
                end

                div class: 'text-center' do
                  span 'Temporary Degree Status'
                  status_tag graduate_student.tempo_status
                end
              else
                h3 class: 'text-center no-recent-data' do
                  'Not Uploaded Yet'
                end
              end
            end
          end
        end
      end
      tab 'Student Address' do
        columns do
          column do
            panel 'Student Address' do
              attributes_table_for graduate_student.student_address do
                row :country
                row :city
                row :region
                row :zone
                row :sub_city
                row :house_number
                row :special_location
                row :moblie_number
                row :telephone_number
                row :pobox
                row :woreda
              end
            end
          end
          column do
            panel 'Student Emergency Contact information' do
              attributes_table_for graduate_student.emergency_contact do
                row :full_name
                row :relationship
                row :cell_phone
                row :email
                row :current_occupation
                row :name_of_current_employer
                row :email_of_employer
                row :office_phone_number
                row :pobox
              end
            end
          end
        end
      end
      tab 'Student Course' do
        panel 'Course list' do
          table_for graduate_student.student_courses.order('year ASC, semester ASC') do
            ## TODO: wordwrap titles and long texts
            column :course_title
            column :course_code
            column :credit_hour
            column :ects
            column :semester
            column :year
            column :letter_grade
            column :grade_point
          end
        end
      end
      tab 'Grade Report' do
        panel 'Grade Report', html: { loading: 'lazy' } do
          table_for graduate_student.grade_reports.order('year ASC, semester ASC') do
            column 'Academic Year', sortable: true do |n|
              link_to n.academic_calendar.calender_year_in_gc, admin_academic_calendar_path(n.academic_calendar)
            end
            column :year
            column :semester
            column 'SGPA', :sgpa
            column 'CGPA', :cgpa
            column :academic_status
            column 'Issue Date', sortable: true do |c|
              c.created_at.strftime('%b %d, %Y')
            end
            column 'Actions', sortable: true do |c|
              link_to 'view', admin_grade_report_path(c.id)
            end
          end
        end
      end
    end
  end
end
