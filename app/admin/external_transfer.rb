# frozen_string_literal: true

ActiveAdmin.register ExternalTransfer do
  menu parent: 'Add-ons', label: 'Student Transfer'

  permit_params :first_name, :last_name, :department_id, :previous_institution, :previous_student_id, :status, :created_at,
                :updated_at, :study_level, :admission_type, :message, :email, course_exemptions_attributes: %i[id course_id
                                                                                                               letter_grade
                                                                                                               credit_hour
                                                                                                               course_taken
                                                                                                               exemption_approval
                                                                                                               exemption_type
                                                                                                               exemptible_type
                                                                                                               exemptible_id
                                                                                                               created_by
                                                                                                               updated_by
                                                                                                               created_at
                                                                                                               updated_at _destroy]
  # Filters on the index page
  filter :first_name
  filter :last_name
  filter :email
  # filter :status, as: :select, collection: ExternalTransfer.statuses.keys
  filter :department
  filter :previous_institution
  filter :created_at
  filter :updated_at

  scope :all, default: true
  scope :approved_finance_status do |transfers|
    transfers.where(finance_status: 'approved')
  end

  # Index page configurations
  index do
    selectable_column
    # id_column
    column :first_name
    column :last_name
    column :email
    column :department
    column :previous_institution
    column 'Attachment' do |me|
      if me.receipt.attached?
        link_to 'View Receipt', url_for(me.receipt)
      else
        'No Receipt'
      end
    end
    column :created_at
    column :updated_at
    actions
  end

  # Show page configurations
  show do
    attributes_table do
      row :first_name
      row :last_name
      row :email
      row :department
      row :previous_institution
      row :previous_student_id
      row :status do |transfer|
        status_tag transfer.status
      end
      row :study_level
      row :admission_type
      row :message
      row :approved_by
      row :transcript do |transfer|
        if transfer.transcript.attached?
          link_to 'Download Transcript', rails_blob_path(transfer.transcript, disposition: 'attachment')
        else
          'No Transcript Attached'
        end
      end
      row 'Attachment' do |me|
        if me.receipt.attached?
          link_to me.receipt.filename.to_s, url_for(me.receipt)
        else
          'No reciept'
        end
      end
      row :created_at
      row :updated_at
    end

    if resource.course_exemptions.any?
      panel 'Course Exemptions' do
        table_for resource.course_exemptions do
          column('Course') { |ex| ex.course&.course_title }
          column('Letter Grade', &:letter_grade)
          column('Credit Hour', &:credit_hour)
          column('Course Taken', &:course_taken)
          column('Exemption Approval', &:exemption_approval)
        end
      end
    end

    if external_transfer.accepted? && external_transfer.finance_status == 'approved'
      panel 'Actions' do
        link_to 'Create Exemption',
                new_admin_exemption_path(external_transfer_id: external_transfer.id, program_id: external_transfer.program_id), class: 'button'
      end
    end

    active_admin_comments
  end

  # Form configuration for new and edit actions
  form do |f|
    f.semantic_errors

    f.inputs do
      f.input :first_name
      f.input :last_name
      f.input :email
      f.input :department, as: :select, collection: Department.all.collect { |department|
                                                      [department.department_name, department.id]
                                                    }
      f.input :previous_institution
      f.input :previous_student_id
      f.input :status, as: :select, collection: ExternalTransfer.statuses.keys
      f.input :study_level
      f.input :admission_type
      f.input :message
      f.input :approved_by
      f.input :transcript, as: :file
    end
    panel 'course exemptions' do
      f.has_many :course_exemptions, heading: ' ', remote: true, allow_destroy: true, new_record: true do |a|
            a.input :course_id, as: :search_select, url: admin_courses_path,
                                fields: %i[course_title id], display_name: 'course_title', minimum_input_length: 2,
                                order_by: 'id_asc'
            a.input :letter_grade
            a.input :credit_hour
            a.input :course_taken
            a.input :exemption_approval, as: :select, collection: %w[Pending Approved Rejected]
            a.label :_destroy
      end
    end

    f.actions
  end

  # Action Items
  action_item :approve, only: :show do
    if external_transfer.pending?
      link_to 'Approve', approval_admin_external_transfer_path(external_transfer),
              method: :put
    end
  end

  # Custom Routes for Approval
  member_action :approval, method: :put do
    resource.update(status: ExternalTransfer.statuses[:accepted], approved_by: current_admin_user.email)
    redirect_to resource_path, notice: 'External Transfer approved successfully.'
  end

  # Batch Actions for Accept and Reject
  batch_action :accept do |ids|
    batch_action_collection.find(ids).each do |external_transfer|
      external_transfer.update(status: 1, approved_by: current_admin_user.email)
    end
    redirect_to collection_path, alert: 'The selected transfers have been accepted.'
  end

  batch_action :reject do |ids|
    batch_action_collection.find(ids).each do |external_transfer|
      external_transfer.update(status: 2, approved_by: current_admin_user.email)
    end
    redirect_to collection_path, alert: 'The selected transfers have been rejected.'
  end

  batch_action :approve_finance_status do |ids|
    batch_action_collection.find(ids).each do |external_transfer|
      external_transfer.update(finance_status: 'approved')
    end
    redirect_to collection_path, alert: 'The finance status of the selected transfers has been approved.'
  end
end
