# Runs in the request: decides whether a student's AI request may go ahead, scrubs it,
# and records it. Everything that reaches the model passes through here first.
module Ai
  class Gate
    MAX_PROMPT = 1000

    def self.call(...) = new(...).call

    def initialize(student:, project:, mode:, prompt:)
      @student, @project, @mode, @raw_prompt = student, project, mode.to_s, prompt.to_s
    end

    def call
      classroom = @project.classroom || @student.primary_classroom
      # Always read the policy fresh: a teacher may have just changed it.
      policy = classroom && AiPolicy.find_by(classroom_id: classroom.id)
      scrubbed = Ai::Scrubber.call(@raw_prompt.truncate(MAX_PROMPT, omission: ""), names: classmate_names(classroom))

      interaction = AiInteraction.new(
        student: @student, project: @project, classroom:, mode: @mode,
        prompt: scrubbed.text.presence || "(empty)", code_snapshot: @project.ruby_source
      )
      if scrubbed.removed.any?
        interaction.flag_reason = "Removed personal info: #{scrubbed.removed.join(', ')}"
        interaction.flag_severity = "info"
      end

      denial = denial_reason(policy, scrubbed.text)
      if denial
        interaction.assign_attributes(status: "denied", response_text: denial)
      end
      interaction.save!
      # Short delay so the student's page has shown the question before the answer is broadcast.
      AiTutorJob.set(wait: 1.second).perform_later(interaction) if interaction.pending?
      interaction
    end

    private
      def denial_reason(policy, text)
        return "AI help isn't set up for your class yet. Ask your teacher." unless policy
        return "Typing questions to the AI is for students 13 and older. Use the question cards instead!" unless @student.typing_allowed?
        return "Typed questions are turned off for your class. Use the question cards instead!" unless policy.light == "green"
        return "#{Ai::MODE_LABELS[@mode] || 'That mode'} isn't available for you right now." unless policy.modes_for(@student).include?(@mode)
        return "You've used all #{policy.daily_limit} AI requests for today. Try solving it yourself — you've got this!" if @student.ai_requests_today >= policy.daily_limit
        "Type a question first." if text.strip.length < 3
      end

      def classmate_names(classroom)
        names = [ @student.name ]
        names += classroom.students.pluck(:name) + [ classroom.teacher.name ] if classroom
        names
      end
  end
end
