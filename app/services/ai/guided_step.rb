# Writes one rung of the hint ladder, either from the hint bank or from Claude with a fixed
# JSON format. AI replies that don't fit the rules are replaced with the hint bank's version.
module Ai
  class GuidedStep
    MAX_TEXT = 500
    MAX_CHOICE = 60

    SCHEMA = {
      type: "object",
      additionalProperties: false,
      properties: {
        text: { type: "string", description: "What the coach says to the student." },
        choices: { type: "array", items: { type: "string" }, description: "Answer buttons. Only for level 1; otherwise empty." },
        line: { anyOf: [ { type: "integer" }, { type: "null" } ], description: "Line number of the student's code this step points at, or null." }
      },
      required: %w[text choices line]
    }.freeze

    def self.call(step) = new(step).call

    def initialize(step)
      @step = step
      @session = step.help_session
    end

    def call
      reply = @session.source == "ai" ? ai_reply || bank_reply(fallback: true) : bank_reply
      @step.assign_attributes(response_text: reply[:text], choices: reply[:choices], line_ref: reply[:line],
                              model: reply[:model], input_tokens: reply[:input_tokens], output_tokens: reply[:output_tokens])
      @step.flag_reason, @step.flag_severity = "AI reply didn't fit the rules; used the hint bank", "info" if reply[:fallback]

      if @session.source == "ai" && @session.classroom&.policy&.review_required?
        @step.status = "held"
      else
        @step.status = "delivered"
        @step.delivered_at = Time.current
      end
      @step.save!
      @step.broadcast_update
    end

    private
      def bank_reply(fallback: false)
        Ai::HintBank.step(@session, @step.level).merge(model: Ai::HintBank::MODEL, input_tokens: 0, output_tokens: 0, fallback:)
      end

      def ai_reply
        response = Ai.client.beta.messages.create(
          model: Ai::TUTOR_MODEL,
          max_tokens: 4000,
          output_config: { effort: "low", format_: { type: :json_schema, schema: SCHEMA } },
          system_: [ { type: "text", text: Ai::Prompts.guided_system(@session), cache_control: { type: "ephemeral" } } ],
          messages: [ { role: "user", content: Ai::Prompts.guided_user(@session, @step.level) } ],
          fallbacks: :default,
          betas: [ "server-side-fallback-2026-07-01" ]
        )
        return if response.stop_reason.in?(%i[refusal max_tokens])

        raw = response.content.select { |b| b.type == :text }.map(&:text).join
        validate(JSON.parse(raw))&.merge(model: response.model.to_s, input_tokens: response.usage.input_tokens,
                                          output_tokens: response.usage.output_tokens, fallback: false)
      rescue JSON::ParserError, Anthropic::Errors::APIError => e
        Rails.logger.warn("[Ai::GuidedStep] #{e.class}: #{e.message}")
        nil
      end

      # Enforces the ladder's rules on whatever the model sent back.
      def validate(data)
        text = data["text"].to_s.strip
        return if text.empty? || text.length > MAX_TEXT
        return if text.include?("```") # no code blocks — only short inline examples
        return if @step.level < 3 && text.scan(/`[^`]+`/).any? { |code| code.length > 40 } # no solutions slipped into hints

        choices = @step.level == 1 ? Array(data["choices"]).map { |c| c.to_s.strip.truncate(MAX_CHOICE) }.reject(&:empty?).first(4) : []
        return if @step.level == 1 && choices.size < 2

        line_count = @session.project.ruby_source.lines.count
        line = data["line"].is_a?(Integer) && data["line"].between?(1, line_count) ? data["line"] : nil
        { text:, choices:, line: }
      end
  end
end
