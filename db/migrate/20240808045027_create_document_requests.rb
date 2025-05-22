class CreateDocumentRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :document_requests do |t|
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.string :mobile_number
      t.string :email
      t.string :admission_type
      t.string :study_level
      t.string :program
      t.string :department
      t.string :student_status
      t.integer :year_of_graduation
      t.string :status, default: 'pending'
      t.string :track_number

      t.timestamps
    end
  end
end
