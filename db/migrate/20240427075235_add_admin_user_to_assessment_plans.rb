class AddAdminUserToAssessmentPlans < ActiveRecord::Migration[7.0]
  def up
    # Add the column as nullable first
    add_reference :assessment_plans, :admin_user, null: true, type: :uuid, foreign_key: true

    # Update existing records to have a default admin_user_id
    # Ensure you have at least one AdminUser in your database
    # You might want to customize how you pick the default admin user
    first_admin_user = AdminUser.first

    if first_admin_user
      AssessmentPlan.update_all(admin_user_id: first_admin_user.id)
    else
      # Handle case where no AdminUser exists (e.g., raise an error or log a warning)
      raise 'No AdminUser found to assign to existing AssessmentPlan records. Please create an AdminUser first or adjust the migration logic.'
    end

    # Then change the column to be not null
    change_column_null :assessment_plans, :admin_user_id, false
  end

  def down
    # Revert the changes in the reverse order
    remove_reference :assessment_plans, :admin_user, type: :uuid, foreign_key: true
  end
end
