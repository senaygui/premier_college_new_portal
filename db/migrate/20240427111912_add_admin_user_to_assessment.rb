class AddAdminUserToAssessment < ActiveRecord::Migration[7.0]
  def up
    # Add admin_user_id as nullable first
    add_reference :assessments, :admin_user, null: true, type: :uuid, foreign_key: true

    # Backfill existing records with a default admin_user_id
    first_admin_user = AdminUser.first
    if first_admin_user
      Assessment.update_all(admin_user_id: first_admin_user.id)
    else
      raise 'No AdminUser found to assign to existing Assessment records. Please create an AdminUser first or adjust the migration logic.'
    end

    # Then change the column to be not null
    change_column_null :assessments, :admin_user_id, false

    # Add status column
    add_column :assessments, :status, :integer, default: 0

    # Add course_registration_id as nullable first
    add_reference :assessments, :course_registration, null: true, type: :uuid, foreign_key: true

    # Backfill existing records with a default course_registration_id
    first_course_registration = CourseRegistration.first
    if first_course_registration
      Assessment.update_all(course_registration_id: first_course_registration.id)
    else
      # Consider if it's acceptable for assessments to exist without a course_registration_id
      # If not, you'll need to create a default CourseRegistration or adjust your data.
      raise 'No CourseRegistration found to assign to existing Assessment records. Please create one or adjust the migration logic.'
    end

    # Then change the column to be not null
    change_column_null :assessments, :course_registration_id, false

    remove_column :assessments, :student_grade_id
  end

  def down
    # Revert in reverse order
    remove_column :assessments, :status
    remove_reference :assessments, :course_registration, type: :uuid, foreign_key: true
    remove_reference :assessments, :admin_user, type: :uuid, foreign_key: true
    add_column :assessments, :student_grade_id, :uuid # Re-add the removed column
  end
end
