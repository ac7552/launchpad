class AiTutorJob < ApplicationJob
  queue_as :default

  def perform(interaction)
    return unless interaction.pending?
    Ai::Tutor.call(interaction)
  end
end
