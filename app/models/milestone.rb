class Milestone < ApplicationRecord
  CATEGORIES = %w[coding ai computer].freeze

  belongs_to :stage
  has_many :skill_checks, dependent: :destroy

  validates :description, presence: true
  validates :category, inclusion: { in: CATEGORIES }
end
