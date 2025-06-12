
require 'prawn'

class AcademicCalendarPdfGenerator
  def initialize(academic_calendar)
    @academic_calendar = academic_calendar
    @activities = academic_calendar.activities
    @semesters = academic_calendar.semesters
  end

  def render
    pdf = Prawn::Document.new do |pdf|
      header(pdf)
      semesters_table(pdf)
      activities_table(pdf)
    end
    save_to_file(pdf.render)  # Save the PDF to file for debugging
    pdf.render
  rescue StandardError => e
    puts "Error generating PDF: #{e.message}"
    raise e
  end


  private

  def save_to_file(pdf_content)
    File.open("debug_academic_calendar.pdf", "wb") do |file|
      file.write(pdf_content)
    end
  end

  def header(pdf)
    pdf.text "Premier College Portal Academic Calendar", size: 24, style: :bold, align: :center
    pdf.move_down 20
    pdf.text "Calendar Year: #{@academic_calendar.calender_year}", size: 14
    pdf.text "Admission Type: #{@academic_calendar.admission_type}", size: 14
    pdf.text "Study Level: #{@academic_calendar.study_level}", size: 14
    pdf.text "From Year: #{@academic_calendar.from_year}", size: 14
    pdf.text "To Year: #{@academic_calendar.to_year}", size: 14
    pdf.move_down 20
  end

  def semesters_table(pdf)
    pdf.move_down 20
    pdf.text "Semesters", size: 18, style: :bold
    pdf.move_down 10

    table_data = [["Semester", "Starting Date", "Ending Date"]]

    @semesters.each do |semester|
      table_data << [semester.semester, semester.starting_date.strftime("%b %d, %Y"), semester.ending_date.strftime("%b %d, %Y")]
    end

    pdf.table(table_data, header: true) do |table|
      table.row(0).font_style = :bold
      table.header = true
      table.row_colors = ['DDDDDD', 'FFFFFF']
      table.cell_style = { border_width: 1, padding: [8, 12] }
    end
  end

  def activities_table(pdf)
    pdf.move_down 20
    pdf.text "Activities", size: 18, style: :bold
    pdf.move_down 10

    table_data = [["Activity", "Semester", "Start Date", "End Date", "Description"]]

    @activities.each do |activity|
      table_data << [
        activity.activity,
        activity.semester,
        activity.starting_date.strftime("%b %d, %Y"),
        activity.ending_date.strftime("%b %d, %Y"),
        #activity.category,
        activity.description
      ]
    end

    pdf.table(table_data, header: true) do |table|
      table.row(0).font_style = :bold
      table.header = true
      table.row_colors = ['DDDDDD', 'FFFFFF']
      table.cell_style = { border_width: 1, padding: [8, 12] }
    end
  end
end
