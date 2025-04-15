Rails.application.routes.draw do
  get 'readmissions/new'
  get 'readmissions/create'
  get 'readmissions/index'
  get 'document_requests/new'
  get 'document_requests/create'
  get 'document_requests/show'
  get 'reports/course_assignments'
  get 'grade_changes/new'
  get 'grade_changes/create'

  resources :sections, except: [:index] do
    collection do
      get 'assign', to: 'sections#index'
    end
    member do
      get :download_pdf
    end
  end

  resources :attendances do
    member do
      get :download_pdf
    end
  end

  resources :academic_calendars do
    member do
      get :download_pdf
    end
  end

  resources :notices, only: %i[index show new create edit update destroy]
  # resources :makeup_exams, only: [:new, :create]
  resources :withdrawals, only: %i[new create]

  get 'course_assignments', to: 'reports#course_assignments', as: 'course_assignments_report'

  # resources :makeup_exams do
  #  member do
  #    patch :verify
  #  end
  # end
  # get 'courses/pdf/:scope', to: 'courses#pdf_by_scope', as: 'courses_pdf_by_scope'
 # post 'admin/class_schedules/:id/upload_file', to: 'admin/class_schedules#upload_file', as: 'upload_file_admin_class_schedule'

  resources :makeup_exams, only: %i[index new create] do
    member do
      get :payment
      patch :payment, action: :update
      patch :verify
    end
  end

  # resources :payments, only: [:new, :create] do
  #  member do
  #    get :pay
  #  end
  # end

 # resources :sections do
 #   member do
 #     get :download_pdf
 #   end
 # end
#
 # resources :sections, except: [:index] do
 #   collection do
 #     get "assign", to: "sections#index"
 #     # as: "sections"
 #   end
 # end
  get 'apply_grade_change/index'
  get '/available/courses/:course_id/(:drop_id)', to: 'avaliable_courses#index', as: 'available_courses'
  get 'drop_courses/index', as: 'drop_courses'
  get 'add_courses/index', as: 'add_courses'
  post 'create/exemptions/:applicant_id', to: 'exemptions#create', as: 'create_exemptions'
  get 'new/exemptions/:applicant_id/:approved_by', to: 'exemptions#new', as: 'new_exemptions'
  get 'index/exemptions/:applicant_id/:approved_by', to: 'exemptions#index', as: 'index_exemptions'
  get 'edit/exemptions/:applicant_id/:id/:approved_by', to: 'exemptions#edit', as: 'edit_exemptions'
  get 'applicant/search', to: 'external_transfers#search', as: 'external_transfer_search'
  get 'transfer/approval/:id/:approved_by', to: 'external_transfers#approval', as: 'transfer_approval'
  patch 'transfer/approved/:id', to: 'external_transfers#approved', as: 'transfer_approved'
  delete 'delete/exception', to: 'exemptions#destroy', as: 'transfer_destroy'
  resources :avaliable_courses, except: [:index]
  resources :drop_courses do
    member do
      post 'add_course_drop', as: 'add_drop_course'
      post 'withdraw_course'
    end
  end
  # config/routes.rb
  resources :courses do
    resources :assessment_plans, only: %i[index new create edit update destroy]
  end
  resources :courses, only: %i[index show]

  resources :assessment_plans do
    resources :assessments do
      resources :assessment_results, only: [:create]
    end
  end

  resources :document_requests, only: %i[index new create show] do
    member do
      get :payment
      patch :upload_receipt
    end

    collection do
      get :track_form
      post :track
    end
  end
# config/routes.rb
# resources :assessmens do
#  collection do
#    get :missing_assessments_report
#  end
# end

  resources :exemptions

 # resources :exemptions do
 #   collection do
 #     get :courses_for_transfer
 #     #post :select_course
 #   end
 # end

  # resources :external_transfers

  resources :external_transfers do
    collection do
      get :filter_programs
    end

    member do
      get :payment
      patch :payment
    end
  end

  resources :transfers, only: %i[new create] do
    member do
      patch :process_course_exemption
    end
  end

  resources :program_exemptions, only: %i[new create]

  resources :assessmens do
    collection do
      post :bulk_create
      get :find_course
      get :missing_assessments_report
    end
    member do
      put :update_mark
      put :batch_update
    end
  end

  namespace :admin do
    resources :registration_payments do
      member do
        get :download_pdf
      end
    end
  end

  namespace :admin do
    resources :class_schedules do
      collection do
        get :fetch_courses_and_sections
      end
    end
  end

  resources :course_offerings
  resources :class_schedules, only: [:index]
  # resources :class_schedules, only: [:index]
  resources :exam_schedules, only: %i[index new create edit update]

  resources :readmissions, only: %i[index new create] do
    member do
      get :payment
      patch :payment, action: :update
      patch :verify
    end
  end

  get 'student_temporary/index', as: 'student_temporary'
  post 'student/tempo/generate', to: 'student_temporary#generate_pdf', as: 'generate_student_tempo'
  get 'pdf_grade_reports/index', as: 'pdf_gread_report'
  get 'prepare_pdf.pdf', to: 'pdf_grade_reports#prepare_pdf'
  get 'student/tempo/generate.pdf', to: 'student_temporary#generate_pdf'
  get 'graduation/approval', to: 'student_temporary#graduation_approval', as: 'graduation_approval'
  get 'graduation/approval/form', to: 'student_temporary#graduation_approval_form', as: 'graduation_approval_form'
  get 'approved', to: 'student_temporary#approved', as: 'approved'
  get 'student/generate/copy', to: 'student_copy#index', as: 'student_copy'
  post 'student_copy/generate_student_copy', as: 'generate_student_copy'

  resources :student_copy

  get 'new/semester/registration', to: 'pages#enrollement', as: 'enrollement'
  get 'added/course/registration', to: 'pages#add_enrollement', as: 'add_enrollement'

  # post "added/course/registration", to: "pages#added_course_registration", as: "added_course_registration"
  post 'create/semester/registration/(:out_of_batch)', to: 'pages#create_semester_registration',
                                                       as: 'create_semester_registration'

  get 'student/grade/report/:year/:semester', to: 'grade_reports#student_grade_report', as: 'student_grade_report'
  get 'prepare/payment/:semester_registration_id', to: 'invoices#prepare_payment', as: 'prepare_payment'
  post 'create/invoice', to: 'invoices#create_invoice_for_remaining_amount', as: 'create_invoice_for_remaining_amount'
  get 'payment/report/fetch/student', to: 'payment_report#fetch_student', as: 'payment_report_fetch_student'
  get 'get/year', to: 'payment_report#get_year', as: 'payment_report_get_year'
  get 'get/semester', to: 'payment_report#get_semester', as: 'payment_report_get_semester'
  get 'student/report', to: 'student_report#get_student_list', as: 'student_report'
  get '/student/report/year', to: 'student_report#student_report_year', as: 'student_report_year'
  get '/student/report/program', to: 'student_report#student_report_program', as: 'student_report_program'
  get '/student/gc/program', to: 'student_report#student_report_gc', as: 'student_report_gc'
  get '/student/report/gc/year', to: 'student_report#student_report_gc_year', as: 'student_report_gc_year'
  get '/student/report/semester', to: 'student_report#student_report_semester', as: 'student_report_semester'
  get '/prepare/online/student/grade', to: 'online_student_grade#prepare', as: 'online_student_grade_prepare'
  post '/student/pdf/report.pdf', to: 'student_report#student_report_pdf', as: 'student_report_pdf'
  post 'generate/payment/report.pdf', to: 'payment_report#generate_payment_report', as: 'generate_payment_report'
  get '/online/student/grade', to: 'online_student_grade#online_grade', as: 'online_grade'
  post '/approve/online/student/grade', to: 'online_student_grade#approve_grade', as: 'approve_online_grade'
  resources :grade_reports
  resources :academic_calendars, only: %i[show index]
  devise_for :students, controllers: {
                          registrations: 'registrations'
                        }
  authenticated :student do
    root 'pages#dashboard', as: 'authenticated_user_root'
  end
  devise_scope :student do
    put 'update/highschool/transcript', to: 'registrations#update_highschool_transcript',
                                        as: 'update_highschool_transcript'
    put 'update/grade/10/matric', to: 'registrations#update_grade_10_matric', as: 'update_grade_10_matric'
    put 'update/grade/12/matric', to: 'registrations#update_grade_12_matric', as: 'update_grade_12_matric'
    put 'update/coc', to: 'registrations#update_coc', as: 'update_coc'
    put 'update/profile/photo', to: 'registrations#update_profile_photo', as: 'update_profile_photo'
    put 'update/diploma/certificate', to: 'registrations#update_diploma_certificate', as: 'update_diploma_certificate'
    put 'update/degree/certificate', to: 'registrations#update_degree_certificate', as: 'update_degree_certificate'
  end

  namespace :admin do
    resources :sections do
      member do
        get :download_pdf
      end
    end
  end

  resources :semester_registrations do
    member do
      get :download_pdf
    end
  end

  post 'prepare_pdf', to: 'pdf_grade_reports#prepare_pdf', as: 'prepare_pdf'
  get 'admission' => 'pages#admission'
  get 'documents' => 'pages#documents', as: 'documents'
  get 'profile' => 'pages#profile', as: 'profile'
  get 'grade_report' => 'pages#grade_report'
  get 'digital-iteracy-quiz' => 'pages#digital_iteracy_quiz'
  get 'requirements' => 'pages#requirement'
  get 'home' => 'pages#home'
  resources :almunis
  resources :semester_registrations
  resources :invoices
  resources :profiles
  resources :grade_changes, only: %i[new create]
  resources :payment_methods
  resources :payment_transactions
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  root to: 'pages#home'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  # root to: 'application#home'
end
