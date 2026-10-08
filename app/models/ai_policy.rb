class AiPolicy < ApplicationRecord
  # NJSBA-style traffic light.
  LIGHTS = {
    "red" => { label: "Red — no AI", description: "Students get hints from Launchpad's written hint bank. No AI responds to students." },
    "yellow" => { label: "Yellow — guided AI coach", description: "Students pick a question card and the AI coach answers with questions and hints, one step at a time. Students never type to the AI." },
    "green" => { label: "Green — guided coach + typed questions (13+)", description: "Everything in yellow. Students who are 13 or older can also type questions about their project." }
  }.freeze

  belongs_to :classroom

  validates :light, inclusion: { in: LIGHTS.keys }
  validates :daily_limit, numericality: { only_integer: true, in: 0..200 }
  validate :modes_are_known

  before_validation { self.allowed_modes = Array(allowed_modes).compact_blank & Stage::AI_MODES }

  def red? = light == "red"
  def guided_ai? = !red?

  # Free-text modes a student may use. Only green classes, only students 13+, and only what their stage allows.
  def modes_for(student)
    return [] unless light == "green" && student.typing_allowed?
    Stage::AI_MODES & allowed_modes & student.current_stage.ai_modes
  end

  # Where a student's guided hints come from: the AI only if the class allows it, an API key is set,
  # and (under 13) a parent has consented to sharing project data with the AI provider.
  def hint_source_for(student) = (red? || !Ai.live? || !student.ai_sharing_allowed?) ? "bank" : "ai"

  private
    def modes_are_known
      errors.add(:allowed_modes, "contains an unknown mode") unless (allowed_modes - Stage::AI_MODES).empty?
    end
end
