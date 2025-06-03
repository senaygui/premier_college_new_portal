ActiveAdmin.register Readmission do
  menu parent: 'Add-ons', label: 'Readmission'

  permit_params :last_earned_cgpa, :readmission_semester, :readmission_year,
                :reason_for_withdrawal, :registrar_approval_status, :comments,
                :program_id, :department_id, :student_id, :section_id,
                :academic_calendar_id, :finance_approval_status

  index do
    selectable_column
    # id_column
    column :student
    column 'Program' do |pd|
      pd.program.program_name
    end
    # column "Department" do |pd|
    #  pd.department.department_name
    # end
    column :section do |pd|
      pd.section.section_short_name
    end
    column 'Academic Year', sortable: true do |n|
      link_to n.academic_calendar.calender_year, admin_academic_calendar_path(n.academic_calendar)
    end
    column :receipt
    column :last_earned_cgpa
    column :readmission_semester
    column :readmission_year
    # column :reason_for_withdrawal
    # column :registrar_approval
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :student
      row :program
      row :department
      row :section
      row :receipt do |doc|
        if doc.receipt.attached?
          link_to doc.receipt.filename.to_s, rails_blob_path(doc.receipt, disposition: 'attachment')
        else
          'No receipt attached'
        end
      end

      row :academic_calendar
      row :last_earned_cgpa
      row :readmission_semester
      row :readmission_year
      row :reason_for_withdrawal
      row :finance_approval_status do |readmission|
        status_tag readmission.finance_approval_status
      end
      row :registrar_approval_status do |readmission|
        status_tag readmission.registrar_approval_status
      end
      row :comments
      row :created_at
      row :updated_at
    end

    active_admin_comments
  end

  filter :student
  filter :program
  filter :department
  filter :readmission_semester
  filter :readmission_year
  filter :registrar_approval
  filter :created_at

  member_action :approve, method: :put do
    readmission = Readmission.find(params[:id])
    readmission.update(registrar_approval_status: 'approved')
    redirect_to admin_readmissions_path, notice: 'Readmission approved.'
  end

  member_action :reject, method: :put do
    readmission = Readmission.find(params[:id])
    readmission.update(registrar_approval_status: 'rejected')
    redirect_to admin_readmissions_path, notice: 'Readmission rejected.'
  end

  batch_action :approve do |selection|
    Readmission.where(id: selection).each do |readmission|
      readmission.update!(registrar_approval_status: 'approved')
    end
    redirect_to collection_path, alert: 'Selected readmissions have been approved.'
  end

  batch_action :reject do |selection|
    Readmission.where(id: selection).each do |readmission|
      # reason = params[:reason_for_rejection] || "No reason provided"
      readmission.update!(registrar_approval_status: 'rejected')
    end
    redirect_to collection_path, alert: 'Selected readmissions have been rejected.'
  end

  batch_action :approve_finance do |selection|
    if current_admin_user.role == 'finance head'
      Readmission.where(id: selection).each do |readmission|
        readmission.update!(finance_approval_status: 'approved')
      end
      redirect_to collection_path, alert: 'Selected readmissions have been approved by finance.'
    else
      redirect_to collection_path, alert: 'You are not authorized to perform this action.'
    end
  end

  form do |f|
    f.inputs 'Readmission Details' do
      f.input :student
      f.input :program
      f.input :department
      f.input :section
      f.input :academic_calendar
      f.input :last_earned_cgpa
      f.input :readmission_semester
      f.input :readmission_year
      f.input :reason_for_withdrawal
      f.input :registrar_approval_status, as: :select,
                                          collection: %w[pending approved denied incomplete], include_blank: false
      f.input :finance_approval_status, as: :select,
                                        collection: %w[pending approved denied incomplete], include_blank: false
      f.input :comments
    end
    f.actions
  end
end
