ActiveAdmin.register FacultyDean do
  menu parent: %w[College Faculties], priority: 2, label: 'Faculty Dean'
  permit_params :admin_user_id, :faculty_id
  controller do
    def update_resource(object, attributes)
      update_method = attributes.first[:password].present? ? :update : :update_without_password
      object.send(update_method, *attributes)
    end

    def scoped_collection
      AdminUser.where(role: 'dean')
    end
  end
  # collection_action :select_dean, method: :get do
  #   AdminUser.where(role: 'dean')
  # end

  form do |f|
    f.inputs 'Faculty Dean ' do
      f.input :admin_user
      # _id, as: :search_select, url: proc {select_dean_admin_faculty_deans_path}, fields: []
      f.input :faculty_id, as: :search_select, url: proc { admin_faculties_path },
                           fields: %i[faculty_name id], display_name: 'faculty_name', minimum_input_length: 2,
                           order_by: 'created_at_asc'
    end
    f.actions
  end

  index do
    selectable_column
    column 'Dean Name' do |f|
      f.admin_user
    end
    column 'Faculty Name' do |f|
      f.faculty.faculty_name
    end
    column :created_at
    column :updated_at
  end
end
