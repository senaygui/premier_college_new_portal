class ExternalTransfer < ApplicationRecord
  belongs_to :department
  belongs_to :program, optional: true # Assuming a program is optional
  has_many :exemptions
  has_one_attached :transcript, dependent: :destroy
  has_one_attached :receipt, dependent: :destroy # Adding the receipt attachment
  validates :previous_student_id, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  has_many :course_exemptions, as: :exemptible, dependent: :destroy
  accepts_nested_attributes_for :course_exemptions, reject_if: :all_blank, allow_destroy: true
  enum :status, {
    pending: 0,
    accepted: 1,
    rejected: 2
  }
end
