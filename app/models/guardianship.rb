# Links a parent or guardian to a student. Created with an invite token; the parent's login
# is made when they accept it, so one parent can be linked to several children.
class Guardianship < ApplicationRecord
  belongs_to :student, class_name: "User"
  belongs_to :parent, class_name: "User", optional: true

  has_secure_token :token, length: 36

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :name, presence: true, length: { maximum: 100 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { scope: :student_id }

  scope :claimed, -> { where.not(parent_id: nil) }

  def claimed? = parent_id.present?

  def claim!(parent)
    update!(parent:, claimed_at: Time.current)
  end
end
