ActiveAdmin.register ClassSchedule do
  menu parent: 'Add-ons'
  permit_params :course_id, :program_id, :section_id, :day_of_week, :start_time, :end_time, :classroom, :class_type, :instructor_name, :year, :semester

  collection_action :fetch_courses_and_sections, method: :get do
    program = Program.find(params[:program_id])
    year = params[:year]
    semester = params[:semester]

    courses = program.courses.where(year: year, semester: semester).select(:id, :course_title)
    sections = program.sections.where(year: year, semester: semester).select(:id, :section_short_name)

    render json: { courses: courses, sections: sections }
  end

  index do
    selectable_column
    column "Program" do |cs|
      cs.program.program_name
    end
    column "Course" do |cs|
      cs.course.course_title
    end
    column "Section" do |cs|
      cs.section.section_short_name
    end
    column :year
    column :semester
    column :day_of_week
    column :start_time
    column :end_time
    column :classroom
    column :instructor_name
    column "Created At", sortable: true do |cs|
      cs.created_at.strftime("%b %d, %Y")
    end
    actions
  end

  show do
    attributes_table do
      row "Program" do |cs|
        cs.program.program_name
      end
      row "Course" do |cs|
        cs.course.course_title
      end
      row "Section" do |cs|
        cs.section.section_short_name
      end
      row :year
      row :semester
      row :day_of_week
      row :start_time
      row :end_time
      row :classroom
      row :instructor_name
      row "Created At" do |cs|
        cs.created_at.strftime("%b %d, %Y")
      end
    end
    active_admin_comments
  end

  form do |f|
    f.inputs do
      f.input :year, as: :select, collection: [['1', '1'], ['2', '2'], ['3', '3'], ['4', '4'], ['5', '5']]
      f.input :semester, as: :select, collection: [['1', '1'], ['2', '2'], ['3', '3']]
      f.input :program, as: :select, collection: Program.all.map { |p| [p.program_name, p.id] }, input_html: { id: 'program_select', onchange: 'fetchCoursesAndSections()' }
      f.input :course, as: :select, collection: [], input_html: { id: 'course_select' }
      f.input :section, as: :select, collection: [], input_html: { id: 'section_select' }
      f.input :day_of_week, as: :select, collection: [['Monday', 'Monday'], ['Tuesday', 'Tuesday'], ['Wednesday', 'Wednesday'], ['Thursday', 'Thursday'], ['Friday', 'Friday'], ['Saturday', 'Saturday']]
      f.input :start_time, as: :time_picker
      f.input :end_time, as: :time_picker
      f.input :classroom
      f.input :instructor_name
    end
    f.actions

    f.inputs do
      f.template.render 'admin/class_schedules/fetch_courses_and_sections_js'
    end
  end
end
