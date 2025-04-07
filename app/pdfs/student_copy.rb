class StudentCopy < Prawn::Document
  def initialize(students, gc_date)
    super(page_layout: :landscape, background: open('app/assets/images/logo.png'))
    @students = students
    gc_date = Date.parse(gc_date)
    @students.each_with_index do |stud, _index|
      text 'HEUC', inline_format: true, size: 12, align: :center, font_style: :bold
      move_down 10
      text 'OFFICE OF THE REGISTRAR', inline_format: true, size: 12, align: :center, font_style: :bold
      move_down 10
      text '<u>STUDENT ACADEMIC RECORD</u>', inline_format: true, size: 12, font_style: :bold, align: :center
      move_down 10
      table [
              [' ', ' ', "Admission Classification: #{stud.admission_type.capitalize}"],
              ['P.O.Box 12382, Addis Ababa, Ethiopia', ' ',
               "Department: #{stud.department.department_name.capitalize}"],
              ["Full Name: #{stud.name.full.capitalize} #{stud.middle_name}",
               "Faculty: #{stud.department.faculty.faculty_name.capitalize}", 'Medium of Instruction: English'],
              ["ID Number: #{stud.student_id}", "Sex: #{stud.gender}",
               "Graduation Status: #{stud.graduation_status.capitalize}"],
              ["Date of Admission: #{stud.admission_date}",
               "Traning Level: #{stud.study_level == 'undergraduate' ? 'Bachelor Degree' : 'Masters Degree'}", "Date of Graduation: #{gc_date.strftime('%B,%d %Y')}"]
            ], width: 700, cell_style: { border_width: 0, padding: 2, font_style: :bold, size: 11 }
      move_down 10
      stroke_horizontal_rule
      move_down 10
      student_copy = stud.course_registrations.order(:semester).group_by { |c| [c.semester, c.year] }
      student_copy.each do |key, value|
        text "<u> Academic Year:#{key[1]}/#{key[1] + 1} Semester #{key[0]}</u>", size: 14, font_style: :bold, inline_format: true
        move_down 10
        table each_stud_in_table(value, key[0]), cell_style: { size: 9, font_style: :bold, align: :center } do
          row(0).font_style = :bold
          column(1).align = :left
          cells[3, 0].align = :right
          cells[3, 1].align = :left
          cells[4, 0].align = :right
          cells[4, 1].align = :left
          row(0).size = 10
        end
        move_down 10
      end
      move_down 10
      text 'THIS TRANSCRIPT IS OFFICIAL ONLY WHEN SIGNED AND SEALED BY THE REGISTRAR.', align: :center
      table [["DATE OF ISSUE: #{Date.current.strftime('%B,%d %Y')}", ' ' 'REGISTRAR: ____________________']],
            width: 700, position: :right, cell_style: { border_width: 0, font_style: :bold }
      header_footer

      start_new_page
    end
  end

  def each_stud_in_table(value, semester)
    student_grade = GradeReport.where(semester:, year: value.first.year).last

    # Handle nil student_grade to avoid NoMethodError
    if student_grade.nil?
      Rails.logger.error "No GradeReport found for semester: #{semester}, year: #{value.first.year}"
      student_grade = GradeReport.new(sgpa: 0, total_credit_hour: 0, total_grade_point: 0, cgpa: 0)
    end

    [
      ["Academic Year: #{value.first.academic_year} Semester #{semester}"],
      ['Course Code', 'Course Title', 'Cr. hr', 'Grade', 'Grade pts']
    ] + value.map do |cr|
      student_grade_entry = cr.course.student_grades.last
      [
        cr.course.course_code,
        cr.course.course_title,
        cr.course.credit_hour,
        student_grade_entry&.letter_grade || 'N/A',
        student_grade_entry&.grade_point || 'N/A'
      ]
    end + [
      ['SGPA', student_grade.sgpa, student_grade.total_credit_hour, '', student_grade.total_grade_point],
      ['CGPA', student_grade.cgpa, student_grade.total_credit_hour, '', student_grade.total_grade_point]
    ]
  end

  def get_major_cumulative(crg)
    major = Major.major_point_and_hour(crg)
    [[' ', 'Major Cumulative Average(MGPA)', "#{major[0]}", ' ', "#{major[1]}", ' ']]
  end

  def header_footer
    # repeat :all do
    #     bounding_box [bounds.left, bounds.top], :width  => bounds.width do
    #         font "Helvetica"
    #     image open("app/assets/images/logo.png"), fit: [120, 100], position: :center
    #         stroke_horizontal_rule
    #     end

    bounding_box [bounds.left, bounds.bottom + 40], width: bounds.width do
      # stroke_horizontal_rule

      # repeat :all do
      text "Grading system:A=Excellent,B=Good,C=Satisfactory,D=Unsatisfactory/Failing,F=Fail,I=Incomplete,DO=Dropout,** Project/Senior Paper, EX=Exempted, NG= No Grade, P=Pass, *= Course Repeated
                     ", align: :left, font_style: :bold
      text 'Points: A=4,A-=3.75,B+=3.5,B=3,B-=2.75,C+=2.5,C=2,C-=1.75,D=1,F=0', font_style: :bold
      # end
    end
  end
end

################################## - LAST ONE - ###################################
# class StudentCopy < Prawn::Document
#  def initialize(students, gc_date)
#    super(page_layout: :landscape)
#    @students = students
#    gc_date = Date.parse(gc_date)
#
#    repeat :all do
#      add_logo
#    end
#
#    @students.each_with_index do |stud, index|
#      header
#      student_details(stud, gc_date)
#      display_academic_records_horizontal(stud)
#      footer
#
#      start_new_page if index < @students.length - 1 # Avoid starting a new page after the last student
#    end
#  end
#
#  def add_logo
#    logo = "app/assets/images/leadstar.jpg"
#    image logo, at: [0, cursor], fit: [50, 50]
#  end
#
#  def header
#    text "LEADSTAR COLLEGE", size: 10, align: :center, style: :bold
#    move_down 3
#    text "OFFICE OF THE REGISTRAR", size: 10, align: :center, style: :bold
#    move_down 3
#    text "<u>STUDENT ACADEMIC RECORD</u>", size: 10, style: :bold, align: :center, inline_format: true
#   text "DATE OF ISSUE: #{Date.current.strftime('%B %d, %Y')}", size: 6, style: :bold
#
#    move_down 3
#  end
#
#  def student_details(stud, gc_date)
#    table [
#      [" ", " ", "Admission Classification: #{stud.admission_type.capitalize}"],
#      ["P.O.Box 12382, Addis Ababa, Ethiopia", " ", "Department: #{stud.program.program_name.capitalize}"],
#      ["Full Name: #{stud.name.full.capitalize} #{stud.middle_name}", "Medium of Instruction: English"],
#      ["ID Number: #{stud.student_id}", "Sex: #{stud.gender}", "Graduation Status: #{stud.graduation_status.capitalize}"],
#      ["Date of Admission: #{stud.admission_date}", "Training Level: #{stud.study_level == 'undergraduate' ? 'Bachelor Degree' : 'Masters Degree'}", "Date of Graduation: #{gc_date.strftime('%B %d, %Y')}"],
#    ], width: bounds.width - 40, cell_style: { border_width: 0, padding: 4, font_style: :bold, size: 9 }
#    move_down 5
#  end
#
#  def display_academic_records_horizontal(stud)
#    student_copy = stud.course_registrations.order(:academic_year, :semester).group_by do |c|
#      if c.course.course_code == 'MBA-772'
#        last_academic_year = stud.course_registrations.maximum(:academic_year)
#        c.semester = 2
#        c.academic_year = last_academic_year
#      end
#      c.academic_year
#    end
#
#    last_record = student_copy.keys.last
#
#    student_copy.each do |year, courses|
#      semester_1 = courses.select { |c| c.semester == 1 }.uniq(&:course_id)
#      semester_2 = courses.select { |c| c.semester == 2 }.uniq(&:course_id)
#
#      text "<u>Academic Year: #{year - 1} / #{year}</u>", size: 10, style: :bold, inline_format: true
#
#      move_down 3
#
#      semester_1_label = year == 2023 ? "Year1-Semester1" : "Year2-Semester1"
#      semester_2_label = year == 2023 ? "Year1-Semester2" : "Year2-Semester2"
#
#
#        data = [
#          [semester_1_label, "", "", "", "", semester_2_label, "", "", "", ""],
#          ["Course Code", "Course Title", "Letter Grade", "Cr.Hrs", "Grade Point",
#          "Course Code", "Course Title", "Letter Grade", "Cr.Hrs", "Grade Point"]
#          ]
#
#      data += semester_rows(semester_1, semester_2)
#
#      academic_year_to_year = { first_year: 1, second_year: 2 }
#      mapped_year = academic_year_to_year[:first_year] if year == 2023
#      mapped_year = academic_year_to_year[:second_year] if year == 2024
#
#      # Fetch SGPA and CGPA for both semesters
#      sgpa_1, cgpa_1 = fetch_sgpa_and_cgpa(stud, mapped_year, 1)
#      sgpa_2, cgpa_2 = fetch_sgpa_and_cgpa(stud, mapped_year, 2)
#
#      total_cr_hours_1 = semester_1.sum { |c| c.course.credit_hour.to_i }
#      total_grade_points_1 = semester_1.sum { |c| fetch_student_grade_point(c).to_f }
#
#      total_cr_hours_2 = semester_2.sum { |c| c.course.credit_hour.to_i }
#      total_grade_points_2 = semester_2.sum { |c| fetch_student_grade_point(c).to_f }
#
#      data += [
#        [
#          { content: "SGPA", colspan: 2, inline_format: true },
#          sgpa_1, total_cr_hours_1, total_grade_points_1,  # Display SGPA, total Cr.Hrs, and total Grade Points for Semester 1
#          { content: "SGPA", colspan: 2, inline_format: true },
#          sgpa_2, total_cr_hours_2, total_grade_points_2  # Display SGPA, total Cr.Hrs, and total Grade Points for Semester 2
#        ],
#        [
#          { content: "CGPA", colspan: 2, inline_format: true },
#          cgpa_1, "", "",  # Display CGPA for Semester 1
#          { content: "CGPA", colspan: 2, inline_format: true },
#          cgpa_2, "", ""   # Display CGPA for Semester 2
#        ]
#      ]
#
#      table(data, width: bounds.width - 40, cell_style: { size: 8, font_style: :bold, align: :center, padding: 2 }) do
#        row(0).font_style = :bold
#        row(1).font_style = :bold
#        row(1).size = 8
#        row(1).align = :center
#        column(1).align = :left
#      end
#
#      move_down 10
#    end
#  end
#
#  def fetch_sgpa_and_cgpa(student, year, semester)
#    grade_report = GradeReport.where(student_id: student.id, year: year, semester: semester).last
#
#    if grade_report.nil?
#      Rails.logger.warn "Grade report not found for student_id: #{student.id}, year: #{year}, semester: #{semester}"
#    else
#      Rails.logger.info "Grade report found: #{grade_report.inspect}"
#    end
#
#    sgpa = grade_report&.sgpa&.round(2) || 0.0
#    cgpa = grade_report&.cgpa&.round(2) || 0.0
#
#    [sgpa, cgpa]
#  end
#
#  def semester_rows(semester_1, semester_2)
#    max_rows = [semester_1.size, semester_2.size].max
#    (0...max_rows).map do |i|
#      sem_1_row = semester_1[i]
#      sem_2_row = semester_2[i]
#
#      [
#        sem_1_row&.course&.course_code || "",
#        sem_1_row&.course&.course_title || "",
#        fetch_student_grade(sem_1_row),  # Letter Grade first
#        sem_1_row&.course&.credit_hour || "",  # Cr.Hrs
#        fetch_student_grade_point(sem_1_row),  # Grade Point
#        sem_2_row&.course&.course_code || "",
#        sem_2_row&.course&.course_title || "",
#        fetch_student_grade(sem_2_row),  # Letter Grade first
#        sem_2_row&.course&.credit_hour || "",  # Cr.Hrs
#        fetch_student_grade_point(sem_2_row)   # Grade Point
#      ]
#    end
#  end
#
#  def fetch_student_grade(course_registration)
#    return "" unless course_registration
#
#    student_grade = StudentGrade.where(
#      student_id: course_registration.student_id,
#      course_id: course_registration.course_id
#    ).order(created_at: :desc).first
#
#    student_grade&.letter_grade || ""
#  end
#
#  def fetch_student_grade_point(course_registration)
#    return "" unless course_registration
#
#    student_grade = StudentGrade.where(
#      student_id: course_registration.student_id,
#      course_id: course_registration.course_id
#    ).order(created_at: :desc).first
#    student_grade&.grade_point || 0
#  end
#
#  def calculate_sgpa(courses)
#    total_grade_points = 0.0
#    total_credit_hours = 0
#
#    courses.each do |course|
#      credit_hour = course.course.credit_hour.to_i
#      grade_point = fetch_student_grade_point(course).to_f
#      total_grade_points += grade_point
#      total_credit_hours += credit_hour
#    end
#
#    sgpa = total_credit_hours > 0 ? (total_grade_points / total_credit_hours).round(2) : 0.0
#    [sgpa, total_credit_hours]
#  end
#
#  def calculate_cgpa(student)
#    sorted_courses = student.course_registrations.order(:academic_year, :semester)
#    total_grade_points = 0.0
#    total_credit_hours = 0
#
#    first_year = sorted_courses.first&.academic_year
#    first_semester = sorted_courses.first&.semester
#
#    sorted_courses.each do |course|
#      credit_hour = course.course.credit_hour.to_i
#      grade_point = fetch_student_grade_point(course).to_f
#
#      total_grade_points += grade_point
#      total_credit_hours += credit_hour
#    end
#
#    cgpa = total_credit_hours > 0 ? (total_grade_points / total_credit_hours).round(2) : 0.0
#    cgpa
#  end
#  def footer
#    # Check if enough space is available on the current page
#   # move_down 10  # Optional: Adjust this to provide some buffer space before the footer
#
#    if cursor > 50  # Ensure there is enough space (adjust '50' based on your footer content height)
#      # Create a bounding box for the footer
#      bounding_box([bounds.left, bounds.bottom + 20], width: bounds.width) do
#        # Add the grading system text
#        text "Grading system: A=Excellent, B=Good, C=Satisfactory, D=Unsatisfactory/Failing, F=Fail, I=Incomplete, DO=Dropout, ** Project/Senior Paper, EX=Exempted, NG= No Grade, P=Pass, *= Course Repeated, Points: A=4, A-=3.75, B+=3.5, B=3, B-=2.75, C+=2.5, C=2, C-=1.75, D=1, F=0", align: :left, size: 6, style: :bold
#    #    move_down 2 # Move down a bit for spacing
#
#        # Add the date of issue
#        #text "DATE OF ISSUE: #{Date.current.strftime('%B %d, %Y')}", size: 6, style: :bold
#
#        # Add the registrar line
#        text "REGISTRAR: ____________________", size: 6, style: :bold, align: :center
#      end
#    else
#      start_new_page  # Force a new page if not enough space for the footer
#      footer  # Add the footer on the new page
#    end
#  end
# end
#
