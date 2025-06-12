ActiveAdmin.register ClassScheduleWithFile do
  menu parent: 'Add-ons'
    permit_params :name, :file_attachment


    member_action :upload_file, method: [:get, :patch] do
    if request.patch?
      if params[:class_schedule_with_file][:file_attachment].present?
        resource.file_attachment.attach(params[:class_schedule_with_file][:file_attachment])
        redirect_to resource_path, notice: "File uploaded successfully."
      else
        flash[:error] = "Please select a file to upload."
        render :upload_file
         end
        end
     end

    index do
      selectable_column
      column :name
      column :file_attachment
      column "Uploaded At", sortable: true do |cs|
        cs.created_at.strftime("%b %d, %Y")
      end
      actions
    end
  
    show do
        attributes_table do
          row :name
          row :file_attachment do |cs|
            if cs.file_attachment.attached?
              link_to cs.file_attachment.filename, rails_blob_path(cs.file_attachment, disposition: "attachment")
            else
              "No file attached"
            end
          end
        end
        #actions do
        #  link_to "Upload File", upload_file_admin_class_schedule_with_file_path(resource)
        #end
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
      @class_schedule_with_file = ClassScheduleWithFile.new(permitted_params[:class_schedule_with_file].except(:file_attachment))
  
      if @class_schedule_with_file.save
        redirect_to edit_admin_class_schedule_with_file_path(@class_schedule_with_file), notice: "Class schedule created. You can now attach a file."
      else
        flash[:error] = "Could not create ClassScheduleWithFile: #{@class_schedule_with_file.errors.full_messages.join(', ')}"
        render :new
      end
    end
  end

  def update
    @class_schedule_with_file = ClassScheduleWithFile.find(params[:id])
  
    if @class_schedule_with_file.update(permitted_params[:class_schedule_with_file].except(:file_attachment))
      # Reload the record to ensure it's fully persisted
      @class_schedule_with_file.reload
  
      # Attach the file if it is present in the update request
      if params[:class_schedule_with_file][:file_attachment].present?
        @class_schedule_with_file.file_attachment.attach(params[:class_schedule_with_file][:file_attachment])
      end
  
      redirect_to admin_class_schedule_with_file_path(@class_schedule_with_file), notice: "Class schedule updated successfully."
    else
      flash[:error] = "Could not update ClassScheduleWithFile: #{@class_schedule_with_file.errors.full_messages.join(', ')}"
      render :edit
    end
  end
  
  
end
  