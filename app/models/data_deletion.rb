# Proof that a child's data was deleted, and why, without keeping any of it.
class DataDeletion < ApplicationRecord
  REASONS = %w[parent_request parent_declined consent_expired inactive staff_request].freeze

  belongs_to :requested_by, class_name: "User", optional: true

  validates :reason, inclusion: { in: REASONS }

  # Deletes a student and everything tied to them, then records that it happened.
  def self.erase!(student, reason:, requested_by: nil)
    transaction do
      counts = {
        projects: student.projects.count,
        ai_interactions: student.ai_interactions.count,
        help_sessions: student.help_sessions.count
      }
      former_user_id = student.id
      AiInteraction.where(student:).delete_all
      student.destroy!
      create!(former_user_id:, reason:, counts:, requested_by:, deleted_at: Time.current)
    end
  end
end
