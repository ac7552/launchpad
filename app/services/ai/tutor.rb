# Runs in a background job: safety check, then the tutor model, then delivery or hold-for-review.
module Ai
  class Tutor
    FLAGGED_MESSAGES = {
      "urgent" => "It sounds like something might be hard right now. Please talk to your teacher or another adult you trust — they want to help. I've let your teacher know.",
      "review" => "I can't help with that message. Your teacher will take a look. Try asking me about your code!"
    }.freeze
    DECLINED_MESSAGE = "I can't help with that one. Try asking me about your code!".freeze
    ERROR_MESSAGE = "Something went wrong on my end. Try again in a minute.".freeze

    def self.call(interaction) = new(interaction).call

    def initialize(interaction)
      @interaction = interaction
      @student = interaction.student
      @project = interaction.project
    end

    def call
      safety = Ai::SafetyCheck.call(@interaction.prompt, grade: @student.grade)
      return flag!(safety) if safety.flagged?

      reply = Ai.live? ? ask_claude : Ai::OfflineTutor.call(@interaction)
      text, code = split_code(reply[:text])
      @interaction.assign_attributes(
        response_text: text, model: reply[:model],
        input_tokens: reply[:input_tokens], output_tokens: reply[:output_tokens]
      )
      if reply[:declined]
        @interaction.assign_attributes(response_text: DECLINED_MESSAGE, flag_reason: "Model declined the request", flag_severity: "review")
      elsif @interaction.mode == "build" && code.present?
        @interaction.assign_attributes(proposed_code: code, proposal_state: "open")
      end

      @interaction.status = review_required? ? "held" : "delivered"
      @interaction.save!
      @interaction.broadcast_update
    rescue Anthropic::Errors::APIError => e
      Rails.logger.error("[Ai::Tutor] #{e.class}: #{e.message}")
      @interaction.update!(status: "error", response_text: ERROR_MESSAGE)
      @interaction.broadcast_update
    end

    private
      def ask_claude
        stage = @project.stage
        response = Ai.client.beta.messages.create(
          model: Ai::TUTOR_MODEL,
          max_tokens: 16_000,
          output_config: { effort: @interaction.mode == "build" ? "medium" : "low" },
          system_: [ { type: "text", text: Ai::Prompts.system_prompt(stage:, grade: @student.grade, mode: @interaction.mode),
                       cache_control: { type: "ephemeral" } } ],
          messages: [ { role: "user", content: Ai::Prompts.user_message(@interaction, history:) } ],
          # Retry on a substitute model if a safety classifier declines a legitimate request.
          fallbacks: :default,
          betas: [ "server-side-fallback-2026-07-01" ]
        )
        {
          text: response.content.select { |b| b.type == :text }.map(&:text).join("\n").strip,
          declined: response.stop_reason == :refusal,
          model: response.model.to_s,
          input_tokens: response.usage.input_tokens,
          output_tokens: response.usage.output_tokens
        }
      end

      def history
        @project.ai_interactions.where(status: "delivered").where.not(id: @interaction.id).last(2)
      end

      def review_required?
        @interaction.classroom&.policy&.review_required?
      end

      def flag!(safety)
        @interaction.update!(
          status: "flagged", flag_reason: "#{safety.category}: #{safety.reason}", flag_severity: safety.severity,
          response_text: FLAGGED_MESSAGES.fetch(safety.severity)
        )
        @interaction.broadcast_update
      end

      def split_code(text)
        code = nil
        rest = text.to_s.sub(/```ruby\s*\n(.*?)```/m) { code = $1.rstrip; "[The code is below — read it before you accept it.]" }
        [ rest.strip, code ]
      end
  end
end
