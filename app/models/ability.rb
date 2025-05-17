class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= AdminUser.new

    case user.role

    # when "student"
    #  can :read, Notice

    when 'president'
      can :manage, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
      can :read, ActiveAdmin::Page, name: 'Graduation', namespace_name: 'admin'
      can :read, AcademicCalendar

    when 'vice president'
      can :manage, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
      can :read, ActiveAdmin::Page, name: 'Graduation', namespace_name: 'admin'
      can :read, AcademicCalendar
      can :read, Curriculum

    when 'program office'
      can :manage, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
      # can :manage, ClassSchedule
      # can :manage, ExamSchedule
      # can :read, AcademicCalendar

    when 'admin'
      # can :manage, ActiveAdmin::Page, name: "Calendar", namespace_name: "admin"
      can %i[read update], UneditableCurriculum, created_at: (5.days.ago..)
      can :manage, Transfer
      can :manage, DocumentRequest
      can :manage, RecurringPayment
      can :manage, GradeSystem
      can :manage, GradeChange
      can :manage, MakeupExam
      can :manage, AssessmentPlan
      can :manage, CourseRegistration
      can :manage, Attendance
      can :manage, Session
      can :manage, FacultyDean
      can :manage, ProgramExemption # , department_id: user.department.id
      can :manage, Readmission
      can :manage, ExternalTransfer
      # can :manage, ClassSchedule
      can :manage, ClassScheduleWithFile
      can :manage, ExamScheduleWithFile
      can :manage, CourseOffering
      # can :manage, Graduation
      can :manage, PaymentTransaction
      can :manage, StudentAddress
      can :manage, EmergencyContact
      can :manage, Payment
      # can :manage, CourseSection
      can :manage, StudentGrade
      # can :update, StudentGrade
      # can :destroy, StudentGrade
      # cannot :create, StudentGrade
      can :manage, GradeReport
      # can :manage, GradeRule
      can :manage, Grade
      can :manage, AdminUser
      can :manage, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
      can :manage, ActiveAdmin::Page, name: 'Graduation', namespace_name: 'admin'
      can :manage, ActiveAdmin::Page, name: 'AssignSection', namespace_name: 'admin'

      can :manage, Program
      can :manage, College
      can :manage, Faculty
      can :manage, Curriculum
      # TODO: after one college created disable new action
      cannot :destroy, College, id: 1

      can :manage, Department
      # can :manage, Report
      can :manage, CourseModule
      can :manage, Course
      can :manage, Student
      can :manage, PaymentMethod
      can :manage, AcademicCalendar
      can :manage, CollegePayment
      can :manage, SemesterRegistration
      can :manage, Invoice
      can :manage, Section
      can :manage, Almuni
      can :manage, Withdrawal
      can :manage, AddAndDrop
      can %i[read update destroy], Dropcourse
      can %i[read update], AddCourse
      # can :manage, Assessment
      can :manage, OtherPayment
      can :manage, StudentGrade
      can :manage, Exemption
      can :manage, Notice
    when 'instructor'
      can :manage, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
      can :read, AcademicCalendar
      can :read, Course, id: Course.instructor_courses(user.id)
      can :update, Course, id: Course.instructor_courses(user.id)
      can :manage, AssessmentPlan, admin_user_id: user.id
      can %i[read update], MakeupExam
      can :read, CourseRegistration, course_id: Course.instructor_courses(user.id)
      can %i[read update], StudentGrade, course_id: Section.instructors(user.id)
      can %i[read destroy], StudentGrade, course_id: Course.instructor_courses(user.id)
      can :read, Notice
      can :read, StudentGrade, course_id: Course.instructor_courses(user.id)
      can :update, StudentGrade, course_id: Course.instructor_courses(user.id)
      # Destroy action with a block for additional conditions
      can :destroy, StudentGrade do |grade|
        Course.instructor_courses(user.id).include?(grade.course_id) && grade.created_at >= 15.days.ago
      end
      can :read, Program
      # cannot :destroy, StudentGrade
      # can %i[create read destroy], Assessment, admin_user_id: user.id
      can :manage, Attendance
      # can :update, Attendance, section_id: Section.instructor_courses(user.id)
      # can :manage, Session
      # can :read, Session, course_id: Section.instructors(user.id)
      # can :update, Session, course_id: Section.instructors(user.id)
      # cannot :destroy, Session, course_id: Section.instructors(user.id)
      can :read, GradeChange, course_id: Section.instructors(user.id)
      can :update, GradeChange, course_id: Section.instructors(user.id)
    when 'finance'
      can :manage, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
      can :manage, ActiveAdmin::Page, name: 'FinanceReport', namespace_name: 'admin'

      can :read, Program
      # TODO: after one college created disable new action
      # cannot :destroy, College, id: 1

      can :read, Department
      can :read, CourseModule
      can :read, Course
      can :read, Student
      can :manage, PaymentMethod
      can :read, AcademicCalendar
      can :manage, CollegePayment
      can :read, SemesterRegistration
      can :manage, Invoice
    when 'registrar head'
      can :manage, Assessment
      can %i[read update], Transfer
      can :manage, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
      can :manage, ActiveAdmin::Page, name: 'Graduation', namespace_name: 'admin'
      can :manage, ActiveAdmin::Page, name: 'StudentReport', namespace_name: 'admin'
      can :manage, ActiveAdmin::Page, name: 'OnlineStudentGrade', namespace_name: 'admin'
      can :manage, AcademicCalendar
      can :manage, AdminUser, role: 'instructor'
      can %i[read update], Exemption # , dean_approval_status: 'dean_approval_approved'
      can :manage, Faculty
      can :read, CourseModule
      can :read, Program
      can :read, Curriculum
      can :read, Course
      can %i[update read], GradeSystem
      can :read, AssessmentPlan
      can :manage, Section
      can :manage, Student
      can :manage, SemesterRegistration
      can :manage, CourseRegistration
      can :read, CollegePayment
      can :read, PaymentMethod
      can :read, Invoice
      can :manage, Attendance
      can :manage, Session
      can %i[read update], MakeupExam
      can %i[update read], GradeReport
      cannot :destroy, GradeReport
      can :read, StudentGrade
      can :manage, GradeChange
      can :manage, Withdrawal
      can :destroy, Withdrawal, created_by: user.name.full
      can %i[read update], ProgramExemption
      can :manage, AddAndDrop
      cannot :destroy, AddAndDrop, created_by: 'self'
      can :manage, Notice
    when 'data encoder'
      can :manage, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
      can :manage, AcademicCalendar
      can :manage, AdminUser, role: 'instructor'
      can :manage, Faculty
      can :manage, Department
      can :read, CourseModule
      can :read, Program
      can :read, Curriculum
      can :read, Course
      can %i[update read], GradeSystem
      can :read, AssessmentPlan
      can :manage, Section
      can :manage, Student
      can :manage, SemesterRegistration
      can :manage, CourseRegistration
      can :read, CollegePayment
      can :read, PaymentMethod
      can :read, Invoice
      can :manage, Attendance
      can :manage, Session

      # can [:update, :read], GradeReport
      # cannot :destroy, GradeReport
      can :read, StudentGrade
      can :manage, GradeChange
      can :manage, Withdrawal
      can :destroy, Withdrawal, created_by: user.name.full

      can :manage, AddAndDrop
      cannot :destroy, AddAndDrop, created_by: 'self'

    when 'distance_registrar'
      can :manage, CourseSection
      can :manage, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
      can :manage, Student, admission_type: 'distance'
      can :read, Program, admission_type: 'distance'
      can :read, AcademicCalendar, admission_type: 'distance'
      can :manage, Department
      can :read, CourseModule
      can :read, Course
      can :manage, SemesterRegistration, admission_type: 'distance'
      can :read, Invoice
    when 'online_registrar'
      can :manage, CourseSection
      can :read, StudentGrade
      can :read, GradeReport
      can :read, GradeRule
      can :read, Grade
      can :manage, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
      can :manage, Student, admission_type: 'online'
      can :read, Program, admission_type: 'online'
      can :read, AcademicCalendar, admission_type: 'online'
      can :manage, Department
      can :read, CourseModule
      can :read, Course
      can :manage, SemesterRegistration, admission_type: 'online'
      can :read, Invoice
      can :manage, Transfer
    when 'regular_registrar'
      can :manage, CourseSection
      can :manage, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
      can :read, AcademicCalendar, admission_type: 'regular'
      can :manage, Student, admission_type: 'regular'
      can :read, Program, admission_type: 'regular'
      can :manage, Department
      can :read, CourseModule
      can :read, Course
      can :manage, SemesterRegistration, admission_type: 'regular'
      can :read, Invoice
    when 'extention_registrar'
      can :manage, CourseSection
      can :manage, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
      can :manage, Student, admission_type: 'extention'
      can :read, AcademicCalendar, admission_type: 'extention'
      can :read, Program, admission_type: 'extention'
      can :manage, Department
      can :read, CourseModule
      can :read, Course
      can :manage, SemesterRegistration, admission_type: 'extention'
      can :read, Invoice
    when 'finance head'
      can :manage, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
      can :manage, ActiveAdmin::Page, name: 'FinanceReport', namespace_name: 'admin'

      can %i[read update], MakeupExam
      can %i[read update], Withdrawal
      can %i[read update], AddCourse
      can %i[read update], ExternalTransfer
      can %i[read update], Readmission

      can :manage, Invoice
      can :manage, Payment
      cannot :destroy, Invoice
      can :manage, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
      can :read, Program
      # TODO: after one college created disable new action
      # cannot :destroy, College, id: 1

      can :read, Department
      can :read, CourseModule
      can :read, Course
      can :read, Student
      can :manage, PaymentMethod
      can :read, AcademicCalendar
      can :manage, CollegePayment
      can :read, SemesterRegistration
      can :manage, Invoice
      can :manage, Notice
    when 'regular_finance'
      can :manage, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
      can :read, Program, admission_type: 'regular'
      # TODO: after one college created disable new action
      # cannot :destroy, College, id: 1

      can :read, Department
      can :read, CourseModule
      can :read, Course
      can :read, Student, admission_type: 'regular'
      can :manage, PaymentMethod
      can :read, AcademicCalendar, admission_type: 'regular'
      can :manage, CollegePayment, admission_type: 'regular'
      can :read, SemesterRegistration, admission_type: 'regular'
      can :manage, Invoice
    when 'distance_finance'
      can :manage, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
      can :read, Program, admission_type: 'distance'
      # TODO: after one college created disable new action
      # cannot :destroy, College, id: 1

      can :read, Department
      can :read, CourseModule
      can :read, Course
      can :read, Student, admission_type: 'distance'
      can :manage, PaymentMethod
      can :read, AcademicCalendar, admission_type: 'distance'
      can :manage, CollegePayment, admission_type: 'distance'
      can :read, SemesterRegistration, admission_type: 'distance'
      can :manage, Invoice
    when 'online_finance'
      can :manage, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
      can :read, Program, admission_type: 'online'
      # TODO: after one college created disable new action
      # cannot :destroy, College, id: 1

      can :read, Department
      can :read, CourseModule
      can :read, Course
      can :read, Student, admission_type: 'online'
      can :manage, PaymentMethod
      can :read, AcademicCalendar, admission_type: 'online'
      can :manage, CollegePayment, admission_type: 'online'
      can :read, SemesterRegistration, admission_type: 'online'
      can :manage, Invoice
    when 'extention_finance'
      can :manage, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
      can :read, Program, admission_type: 'extention'
      # TODO: after one college created disable new action
      # cannot :destroy, College, id: 1

      can :read, Department
      can :read, CourseModule
      can :read, Course
      can :read, Student, admission_type: 'extention'
      can :manage, PaymentMethod
      can :read, AcademicCalendar, admission_type: 'extention'
      can :manage, CollegePayment, admission_type: 'extention'
      can :read, SemesterRegistration, admission_type: 'extention'
      can :manage, Invoice
    when 'department head'
      can %i[read update], UneditableCurriculum, created_at: (5.days.ago..)
      can :read, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
      # can :manage, ActiveAdmin::Page, name: 'ExternalTransfer', namespace_name: 'admin'
      can :manage, ExternalTransfer, department_id: user.department_id
      can %i[read update], Department, department_name: user.department.department_name
      can %i[read update], Dropcourse, department_id: user.department_id
      can %i[read update destroy], AddCourse, department_id: user.department_id
      can %i[read update destroy], CourseModule, department_id: user.department.id
      can :create, CourseModule
      # can :manage, Exemption
      can :manage, ProgramExemption # , department_id: user.department.id
      can :manage, Course, program: { department_id: user.department.id }
      can :create, Course
      can :manage, AdminUser, role: 'instructor'
      can :create, AdminUser
      can :manage, Assessment, student: { department_id: user.department_id }
      can %i[read update destroy], Program, department_id: user.department.id
      can :create, Program
      can %i[read update destroy], Curriculum, program: { department_id: user.department.id }
      can :create, Curriculum
      can %i[read update destroy], GradeSystem, program: { department_id: user.department.id }
      can :create, GradeSystem
      can :manage, AssessmentPlan, course: { program: { department_id: user.department.id } }
      can :create, AssessmentPlan
      can %i[read update], Transfer # , department_id: user.department.id
      can :read, AcademicCalendar
      can :read, Section, program: { department_id: user.department.id }
      can :read, Student, department_id: "#{user.department_id}"
      can :read, CourseRegistration, department_id: user.department.id
      can :read, SemesterRegistration, department_id: user.department.id
      can :read, Attendance, program: { department_id: user.department.id }
      can :read, Session, course: { program: { department_id: user.department.id } }
      can :read, StudentGrade, department_id: user.department.id
      # can %i[read update], StudentGrade, department_id: user.department.id
      can %i[read update], GradeChange, department_id: user.department.id
      can %i[read update], GradeReport, department_id: user.department.id
      can %i[read update], Withdrawal # , department_id: user.department.id
      can %i[read update], AddAndDrop, department_id: user.department.id
      can %i[read update], MakeupExam, department_id: user.department.id
    when 'dean'
      can %i[read update], UneditableCurriculum, created_at: (5.days.ago..)
      can :manage, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
      can %i[read update], Withdrawal, program: { department: { faculty_id: user.faculty_id } }
      can %i[read update], GradeReport, department: { faculty_id: user.faculty_id }
      can %i[read update], MakeupExam, program: { department: { faculty_id: user.faculty_id } }
      can %i[read update], GradeChange # department: {faculty_id: user.faculty_dean}
      can :manage, Assessment
      can :read, AcademicCalendar
      can :read, StudentGrade, department: { faculty_id: user.faculty_id }
      can :manage, Course, program: { department: { faculty_id: user.faculty_id } }
      can :manage, Program, department: { faculty_id: user.faculty_id }
      can :manage, Curriculum, program: { department: { faculty_id: user.faculty_id } }
      can :manage, GradeSystem
      can :manage, AssessmentPlan
      can %i[read update], Exemption
      can :manage, Notice
      can :manage, Department, faculty_id: user.faculty_id
    when 'faculty dean'
      can %i[read update], UneditableCurriculum, created_at: (5.days.ago..)
      can :manage, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
      can :manage, Department, faculty_id: user.faculty.id
     # can %i[read update destroy], Program, department_id: user.department.id
    when 'library head'
      can :manage, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
      can %i[read update], Withdrawal
    when 'store head'
      can :manage, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
      can %i[read update], Withdrawal
    end
  end
end
