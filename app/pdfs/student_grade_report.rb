class StudentGradeReport < Prawn::Document
    def initialize(students)
        super(page_size: 'A4')
        @students = students
        @students.each_with_index do |stud, index|
         # text "Generated Date :- #{Time.zone.now.strftime('%v-%R')}"
         move_down 175
         text "Student's Name: <u>#{stud.student.first_name.capitalize} #{stud.student.middle_name.capitalize} #{stud.student.last_name.capitalize}</u>           Sex: <u>#{stud.student.gender.capitalize}</u>           Year: <u>#{stud.year}</u> ",
              inline_format: true, size: 11.5, font_style: :bold
         move_down 10
         text "Semester: <u>#{stud.semester}</u>         Dept: <u> #{stud.department.department_name.capitalize} </u>",
              inline_format: true, size: 11.5, font_style: :bold
         move_down 10
         text "Program: <u>#{stud.program.program_name}</u>          A/C Year: <u>#{stud.academic_calendar.calender_year}</u>        ID NO: <u>#{stud.student.student_id}</u>  ",
              inline_format: true, size: 11.5, font_style: :bold
         move_down 10
         # stroke_horizontal_rule
         move_down 20
         table each_data_in_table(stud, index) do
            row(0).font_style = :bold
            row(0).size = 10
         end
         move_down 10
         table preview_table(stud) do
            column(1..3).style align: :center
            row(0).font_style = :bold
            row(0).size = 10
         end
         move_down 30
         text "Academic Status: #{stud.academic_status}"
         move_down 10
         text 'Remark: ___________________________'
         move_down 20
         text ' ____________________', align: :center
         move_down 5
         text 'REGISTRAR OFFICE', align: :center
         move_down 20
         text " #{Time.zone.now.strftime('%v-%R')}", size: 9, font_style: :bold
         start_new_page
        end

        header_footer
    end

    def header_footer
        repeat :all do
            bounding_box [bounds.left, bounds.top], width: bounds.width do
                font 'Times-Roman'
                image open('app/assets/images/logo3.jpg'), fit: [120, 100], position: :center
                move_down 10
                text 'Premier College', align: :center, size: 20, font_style: :bold
                move_down 10
                text 'OFFICE OF REGISTRAR', size: 14, align: :center
                move_down 10
                text "STUDENT'S GRADE REPORT", size: 12, align: :center
                stroke_horizontal_rule
            end

            bounding_box [bounds.left, bounds.bottom + 40], width: bounds.width do
                font 'Times-Roman'
                stroke_horizontal_rule
                move_down(5)
                text 'Office OF Registrar', size: 15, align: :center
                text '+251908522222  PoBox.1697/1250 support@premiercollege.edu.et', size: 11, align: :center
            end
        end
    end

        def each_data_in_table(data, _index)
          [
            ['Title of the course', 'Course Number', 'Credit hours', 'Grade', 'Grade Point']
          ] + data.semester_registration.course_registrations.where(enrollment_status: 'enrolled')
                  .includes(:student_grade)
                  .includes(:course)
                  .map.with_index do |course, _index|
                grade_point = course.student_grade&.grade_point
                credit_hour = course.course.credit_hour
                total_grade_point = grade_point && credit_hour ? grade_point * credit_hour : nil

                [course.course.course_title, course.course.course_code, credit_hour, course.student_grade&.letter_grade,
                 total_grade_point]
              end
        end

    # def preview_table(data)
    #    [
    #        ["","Cr.Hrs", "Grade Point", "Cumlative Grade Point\nAverage(CGPA)"],
    #        ["This Semester Total", data.total_credit_hour, data.total_grade_point, data.cgpa ],
    #        ["Previous Semester Total"]+ get_previous_total(data.student, data.semester),
    #        ["Cumulative Point"]+get_cumulative(get_previous_total(data.student, data.semester), data.total_credit_hour, data.total_grade_point, data.cgpa)
    #
    #    ]
    # end
    def preview_table(data)
        current_semester_credit_hours = data.total_credit_hour
        current_semester_grade_points = data.total_grade_point

        previous_semester_credit_hours, previous_semester_grade_points, = get_previous_total(data.student,
                                                                                             data.semester)

        cumulative_credit_hours = current_semester_credit_hours + previous_semester_credit_hours
        cumulative_grade_points = current_semester_grade_points + previous_semester_grade_points

        cgpa_current_semester = current_semester_credit_hours.positive? ? current_semester_grade_points / current_semester_credit_hours : 0.0
        cgpa_previous_semester = previous_semester_credit_hours.positive? ? previous_semester_grade_points / previous_semester_credit_hours : 0.0
        cgpa_cumulative = cumulative_credit_hours.positive? ? cumulative_grade_points / cumulative_credit_hours : 0.0

        [
          ['', 'Cr.Hrs', 'Grade Point', "Cumulative Grade Point\nAverage (CGPA)"],
          ['This Semester Total', current_semester_credit_hours, current_semester_grade_points,
           cgpa_current_semester.round(2)],
          ['Previous Semester Total', previous_semester_credit_hours, previous_semester_grade_points,
           cgpa_previous_semester.round(2)],
          ['Cumulative Point', cumulative_credit_hours, cumulative_grade_points, cgpa_cumulative.round(2)]
        ]
    end

    def get_previous_total(student, current_semester)
      record = GradeReport.select(:total_credit_hour, :total_grade_point,
                                  :cgpa).where("semester<#{current_semester}").where(student:)
        ch = 0.0
        rgp = 0.0
        cgpa = 0.0
        record.each do |grade|
          ch += grade.total_credit_hour
          rgp += grade.total_grade_point
          cgpa += grade.cgpa
        end
      [ch, rgp, cgpa]
    end

    def get_cumulative(previous, *current)
        [previous[0] + current[0], previous[1] + current[1], previous[2] / current[2]]
    end
end

#### this is from leadstar report works for year2, semester 1 students change the methods

# def get_previous_total(student, current_year, current_semester)
#  Rails.logger.debug "Getting previous totals for student: #{student.id}, current year: #{current_year}, current semester: #{current_semester}"
#
#  previous_records = GradeReport
#                     .where(student: student)
#                     .where("year < ? OR (year = ? AND semester < ?)", current_year, current_year, current_semester)
#                     .select(:total_credit_hour, :total_grade_point, :cgpa)
#
#  total_credit_hours = 0.0
#  total_grade_points = 0.0
#  cumulative_gpa = 0.0
#
#  previous_records.each do |record|
#    Rails.logger.debug "Previous grade record: #{record.inspect}"
#    total_credit_hours += record.total_credit_hour
#    total_grade_points += record.total_grade_point
#    cumulative_gpa += record.cgpa
#  end
#
#  Rails.logger.debug "Total credit hours: #{total_credit_hours}, Total grade points: #{total_grade_points}, Cumulative GPA: #{cumulative_gpa}"
#  [total_credit_hours, total_grade_points, cumulative_gpa]
# end

##################################

# def preview_table(data)
#  current_semester_credit_hours = data.total_credit_hour
#  current_semester_grade_points = data.total_grade_point
#
#  previous_semester_credit_hours, previous_semester_grade_points, _ = get_previous_total(data.student, data.year, data.semester)
#
#  cumulative_credit_hours = current_semester_credit_hours + previous_semester_credit_hours
#  cumulative_grade_points = current_semester_grade_points + previous_semester_grade_points
#
#  cgpa_current_semester = current_semester_credit_hours.positive? ? current_semester_grade_points / current_semester_credit_hours : 0.0
#  cgpa_previous_semester = previous_semester_credit_hours.positive? ? previous_semester_grade_points / previous_semester_credit_hours : 0.0
#  cgpa_cumulative = cumulative_credit_hours.positive? ? cumulative_grade_points / cumulative_credit_hours : 0.0
#
#  [
#    ["", "Cr.Hrs", "Grade Point", "Cumulative Grade Point\nAverage (CGPA)"],
#    ["This Semester Total", current_semester_credit_hours, current_semester_grade_points, cgpa_current_semester.round(2)],
#    ["Previous Semester Total", previous_semester_credit_hours, previous_semester_grade_points, cgpa_previous_semester.round(2)],
#    ["Cumulative Point", cumulative_credit_hours, cumulative_grade_points, cgpa_cumulative.round(2)]
#  ]
# end
