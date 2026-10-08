class AiInteraction < ApplicationRecord
  STATUSES = %w[pending held delivered denied flagged error].freeze
  PROPOSAL_STATES = %w[open accepted rejected].freeze

  belongs_to :student, class_name: "User"
  belongs_to :project
  belongs_to :classroom, optional: true
  belongs_to :reviewed_by, class_name: "User", optional: true
  belongs_to :help_session, optional: true

  MODES = (Stage::AI_MODES + %w[guided]).freeze

  validates :mode, inclusion: { in: MODES }
  validates :status, inclusion: { in: STATUSES }
  validates :prompt, presence: true, length: { maximum: 1000 }

  scope :recent, -> { order(created_at: :desc) }
  scope :needs_review, -> { where(status: %w[held flagged]).where(reviewed_at: nil) }

  STATUSES.each { |s| define_method(:"#{s}?") { status == s } }

  def visible_to_student? = delivered? || denied?
  def open_proposal? = delivered? && proposed_code.present? && proposal_state == "open"

  def guided? = mode == "guided"
  def from_hint_bank? = model == Ai::HintBank::MODEL

  # Guided steps re-render their whole session; typed questions re-render themselves.
  def broadcast_update
    if guided?
      help_session.broadcast_update
    else
      broadcast_replace_to [ project, :ai ], target: self, partial: "ai_interactions/ai_interaction", locals: { ai_interaction: self }
    end
  end

  def deliver!(by: nil)
    update!(status: "delivered", delivered_at: Time.current, reviewed_by: by, reviewed_at: (Time.current if by))
    broadcast_update
  end

  def deny!(reason, by: nil)
    update!(status: "denied", response_text: reason, reviewed_by: by, reviewed_at: (Time.current if by))
    broadcast_update
  end
end
