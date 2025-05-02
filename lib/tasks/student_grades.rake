namespace :student_grades do
  desc "Update 'NG' or 'I' grades to 'F' after 7 days"
  task update_incomplete_grades: :environment do
    cutoff_date = 7.days.ago

    StudentGrade.where(letter_grade: %w[NG I])
                .where('updated_at <= ?', cutoff_date)
                .find_each do |grade|
      grade.update_columns(letter_grade: 'F', grade_point: 0)
      Rails.logger.info "Auto-updated StudentGrade ##{grade.id} to 'F'"
    end
  end
end
