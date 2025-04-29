class AcademicCalendar < ApplicationRecord
     # #validations
    validates :calender_year_in_gc, presence: true
    validates :calender_year_in_ec, presence: true
    validates :calender_year, presence: true
    validates :starting_date, presence: true
    validates :ending_date, presence: true
    validates :admission_type, presence: true
    validates :study_level, presence: true

    # #scope
     scope :recently_added, -> { where('created_at >= ?', 1.week.ago) }
     scope :undergraduate, -> { where(study_level: 'undergraduate') }
     scope :graduate, -> { where(study_level: 'graduate') }
     scope :online, -> { where(admission_type: 'online') }
     scope :regular, -> { where(admission_type: 'regular') }
     scope :extention, -> { where(admission_type: 'extention') }
     scope :distance, -> { where(admission_type: 'distance') }

     # #associations
    has_many :students
     has_many :activities, dependent: :destroy
    accepts_nested_attributes_for :activities, reject_if: :all_blank, allow_destroy: true
    has_many :semesters, dependent: :destroy
    accepts_nested_attributes_for :semesters, reject_if: :all_blank, allow_destroy: true
    has_many :semester_registrations
    has_many :course_registrations
    has_many :invoices
    has_many :attendances
    has_many :course_instructors
    has_many :grade_reports
    has_many :grade_changes
    has_many :sessions
    has_many :withdrawals
    has_many :recurring_payments
    has_many :add_and_drops
    has_many :makeup_exams

    def to_ethiopian_date(gregorian_date)
      gregorian_date = Date.parse(gregorian_date.to_s) unless gregorian_date.is_a?(Date)

      # Determine if the Gregorian year is a leap year
      is_gregorian_leap = Date.leap?(gregorian_date.year)
      new_year_day = is_gregorian_leap ? 11 : 12
      ethiopian_new_year = Date.new(gregorian_date.year, 9, new_year_day)
      ethiopian_year = gregorian_date.year - 8

      # If before Ethiopian New Year, adjust year and reference new year date
      if gregorian_date < ethiopian_new_year
        ethiopian_year -= 1
        prev_year_leap = Date.leap?(gregorian_date.year - 1)
        prev_new_year_day = prev_year_leap ? 11 : 12
        ethiopian_new_year = Date.new(gregorian_date.year - 1, 9, prev_new_year_day)
      end

      days_since_new_year = (gregorian_date - ethiopian_new_year).to_i

      if days_since_new_year < 0
        # Handle edge case — should never be negative here, but just in case
        return 'Invalid date'
      end

      ethiopian_month = (days_since_new_year / 30) + 1
      ethiopian_day = (days_since_new_year % 30) + 1

      # Handle Pagumē overflow
      if ethiopian_month == 13
        max_pagume_days = is_gregorian_leap ? 6 : 5
        ethiopian_day = max_pagume_days if ethiopian_day > max_pagume_days
      end

      "#{ethiopian_day}/#{ethiopian_month}/#{ethiopian_year}"
    end
end
