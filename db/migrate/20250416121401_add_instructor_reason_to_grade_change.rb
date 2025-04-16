class AddInstructorReasonToGradeChange < ActiveRecord::Migration[7.0]
  def change
    add_column :grade_changes, :instructor_reason, :string
  end
end
