class Classroom < ApplicationRecord
  belongs_to :teacher, class_name: "User"
  has_many :enrollments, dependent: :destroy
  has_many :students, -> { order(:name) }, through: :enrollments
  has_one :ai_policy, dependent: :destroy
  has_many :projects, dependent: :nullify
  has_many :ai_interactions, dependent: :nullify
  has_many :help_sessions, dependent: :nullify

  validates :name, presence: true

  after_create :create_default_policy

  def policy = ai_policy || create_default_policy

  private
    def create_default_policy
      ai_policy || create_ai_policy!(allowed_modes: Stage::AI_MODES)
    end
end
