class Enrollment < ApplicationRecord
  belongs_to :classroom
  belongs_to :student, class_name: "User"

  validates :student_id, uniqueness: { scope: :classroom_id }
end
