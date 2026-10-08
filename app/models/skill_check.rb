class SkillCheck < ApplicationRecord
  belongs_to :student, class_name: "User"
  belongs_to :milestone
  belongs_to :checked_by, class_name: "User"

  validates :milestone_id, uniqueness: { scope: :student_id }
end
