class Message < ApplicationRecord
  belongs_to :message_thread, touch: true
  belongs_to :author, class_name: "User"

  validates :body, presence: true, length: { maximum: 1000 }

  # Messages are between people only: they never go to the AI. A possible sign of distress is
  # flagged for staff right away.
  before_save { self.urgent = body.to_s.match?(Ai::SafetyCheck::DISTRESS) if author&.student? }
  after_create_commit do
    message_thread.update_column(:last_message_at, created_at)
    broadcast_append_to message_thread, target: "messages", partial: "messages/message", locals: { message: self }
  end

  def from_staff? = author.staff?
end
