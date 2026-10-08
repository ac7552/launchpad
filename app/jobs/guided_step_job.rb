class GuidedStepJob < ApplicationJob
  queue_as :default

  def perform(step)
    return unless step.pending?
    Ai::GuidedStep.call(step)
  end
end
