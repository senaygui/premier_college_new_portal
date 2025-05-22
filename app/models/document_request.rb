class DocumentRequest < ApplicationRecord
  has_one_attached :document
  has_one_attached :receipt

  has_one :other_payment, as: :payable, dependent: :destroy

  validates :first_name, :last_name, :mobile_number, :email, :admission_type, :study_level, :program, :department,
            :student_status, presence: true
  validates :year_of_graduation, presence: true, if: -> { student_status == 'Graduated' }

  before_create :generate_track_number

  private

  def generate_track_number
    self.track_number = SecureRandom.hex(10)
  end
end
