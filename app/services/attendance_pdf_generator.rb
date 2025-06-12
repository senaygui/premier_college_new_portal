require 'prawn'

class AttendancePdfGenerator
  def initialize(attendance)
    @attendance = attendance
    @month = Date.today.strftime('%B')
  end

  def render
    Prawn::Document.new(page_layout: :landscape) do |pdf|
      # Add a repeating header with logo and title
      pdf.repeat(:all) do
        add_header(pdf)
      end

      # Reserve space for the header on every page
      pdf.bounding_box([pdf.bounds.left, pdf.bounds.top - 120], width: pdf.bounds.width,
                                                                height: pdf.bounds.height - 150) do
        # Add attendance details
        pdf.text "Program: #{@attendance.program.program_name}", size: 14
        pdf.text "Course: #{@attendance.course.course_title}", size: 14
        pdf.text "Section: #{@attendance.section.section_full_name}", size: 14
        pdf.text "Year: #{@attendance.year}", size: 14
        pdf.text "Semester: #{@attendance.semester}", size: 14
        pdf.move_down 10

        # Add a placeholder for the date
        pdf.text 'Date: ____________________', size: 14
        pdf.move_down 10

        # Add the attendance table
        attendance_table(pdf)
      end
    end.render
  end

  private

  def add_header(pdf)
    # Logo
    pdf.image 'app/assets/images/logo3.jpg', at: [pdf.bounds.left + 10, pdf.bounds.top - 10]

    # Title
    pdf.text_box 'Premier College Portal Attendance Sheet', at: [0, pdf.bounds.top - 30], width: pdf.bounds.width, align: :center,
                                                            size: 30
  end

  def attendance_table(pdf)
    # Define the table header with days of the week
    table_data = [['Student Name', 'Student ID', 'Mon', 'Tues', 'Wed', 'Thur', 'Fri', 'Sat']]

    # Add rows for each student
    @attendance.section.students.each do |student|
      student_data = ["#{student.first_name} #{student.last_name}", student.student_id, ' ', ' ', ' ', ' ', ' ', ' ']
      table_data << student_data
    end

    # Define column widths for the table
    column_widths = {
      0 => 150, # Student Name
      1 => 100, # Student ID
      2 => 70,  # Monday
      3 => 70,  # Tuesday
      4 => 70,  # Wednesday
      5 => 70,  # Thursday
      6 => 70,  # Friday
      7 => 70   # Saturday
    }

    # Generate the table in the PDF
    pdf.table(table_data, header: true, column_widths:) do |table|
      table.row(0).font_style = :bold
      table.row_colors = %w[DDDDDD FFFFFF]
      table.cell_style = { border_width: 1, padding: [8, 12] }
    end
  end
end
