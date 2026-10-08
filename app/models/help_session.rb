# A guided help request: the student picks a question card, and the coach climbs a hint
# ladder one step at a time — a question first, then a pointer, then a tiny example, then the teacher.
class HelpSession < ApplicationRecord
  STATUSES = %w[open solved escalated resolved abandoned].freeze
  STEP_KINDS = { 1 => "question", 2 => "pointer", 3 => "example", 4 => "teacher" }.freeze
  TEACHER_LEVEL = 4
  SOURCES = %w[ai bank].freeze
  WORKED = "It worked!".freeze
  STUCK = "Still stuck".freeze
  # Students have to actually try a hint before asking for the next one.
  TRY_FIRST_SECONDS = 20

  belongs_to :student, class_name: "User"
  belongs_to :project
  belongs_to :classroom, optional: true
  belongs_to :resolved_by, class_name: "User", optional: true
  has_many :steps, -> { order(:level) }, class_name: "AiInteraction", dependent: :destroy

  validates :card, inclusion: { in: ->(_) { Ai::Cards.keys } }
  validates :status, inclusion: { in: STATUSES }
  validates :source, inclusion: { in: SOURCES }

  scope :needs_teacher, -> { where(status: "escalated") }
  scope :active, -> { where(status: %w[open escalated]) }

  STATUSES.each { |s| define_method(:"#{s}?") { status == s } }

  def card_info = Ai::Cards.fetch(card)
  def current_step = steps.last
  def finished? = status.in?(%w[solved resolved abandoned])

  # Shown to teachers and in logs in place of a typed prompt — students never type here.
  def description
    [ card_info[:label], ("line #{line_number}: #{line_text}" if line_number) ].compact.join(" — ")
  end

  def seconds_until_next_hint
    step = current_step
    return 0 unless step&.delivered_at
    [ TRY_FIRST_SECONDS - (Time.current - step.delivered_at).to_i, 0 ].max
  end

  def broadcast_update
    broadcast_replace_to [ project, :ai ], target: self, partial: "help_sessions/help_session", locals: { help_session: self }
  end
end
