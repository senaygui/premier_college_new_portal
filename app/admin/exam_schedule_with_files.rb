# app/admin/exam_schedule_with_files.rb
ActiveAdmin.register ExamScheduleWithFile do
  menu parent: 'Add-ons'
  permit_params :name, :file_attachment

  index do
    selectable_column
    column :name
    column :file_attachment do |es|
      if es.file_attachment.attached?
        link_to('Download',
                                                   rails_blob_path(es.file_attachment,
                                                                   disposition: 'attachment'))
      else
        'No file attached'
      end
    end
    column 'Uploaded At', sortable: true do |es|
      es.created_at.strftime('%b %d, %Y')
    end
    actions
  end

  show do
    attributes_table do
      row :name
      row :file_attachment do |es|
        if es.file_attachment.attached?
          link_to es.file_attachment.filename, rails_blob_path(es.file_attachment, disposition: 'attachment')
        else
          'No file attached'
        end
      end
      row 'Uploaded At' do |es|
        es.created_at.strftime('%b %d, %Y')
      end
    end
    active_admin_comments
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :file_attachment, as: :file
    end
    f.actions
  end

  controller do
    def create
      @exam_schedule_with_file = ExamScheduleWithFile.new(permitted_params[:exam_schedule_with_file].except(:file_attachment))

      if @exam_schedule_with_file.save
        if params[:exam_schedule_with_file][:file_attachment].present?
          @exam_schedule_with_file.file_attachment.attach(params[:exam_schedule_with_file][:file_attachment])
        end

        redirect_to admin_exam_schedule_with_file_path(@exam_schedule_with_file),
                    notice: 'Exam schedule created successfully.'
      else
        flash[:error] =
          "Could not create ExamScheduleWithFile: #{@exam_schedule_with_file.errors.full_messages.join(', ')}"
        render :new
      end
    end

    def update
      @exam_schedule_with_file = ExamScheduleWithFile.find(params[:id])

      if @exam_schedule_with_file.update(permitted_params[:exam_schedule_with_file].except(:file_attachment))
        if params[:exam_schedule_with_file][:file_attachment].present?
          @exam_schedule_with_file.reload
          @exam_schedule_with_file.file_attachment.attach(params[:exam_schedule_with_file][:file_attachment])
        end

        redirect_to admin_exam_schedule_with_file_path(@exam_schedule_with_file),
                    notice: 'Exam schedule updated successfully.'
      else
        flash[:error] =
          "Could not update ExamScheduleWithFile: #{@exam_schedule_with_file.errors.full_messages.join(', ')}"
        render :edit
      end
    end
  end
end
