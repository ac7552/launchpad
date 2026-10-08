# Screens a student's message before the tutor sees it. A local keyword pass catches the
# urgent cases instantly; when an API key is configured, a small fast model checks the rest.
module Ai
  class SafetyCheck
    Result = Struct.new(:flagged, :category, :reason, :severity, keyword_init: true) do
      def flagged? = flagged
    end

    DISTRESS = /\b(kill(ing)? myself|suicid\w*|want to die|hurt(ing)? myself|self[- ]?harm|cut(ting)? myself|end my life)\b/i
    URGENT = %w[distress harm].freeze

    SYSTEM = <<~PROMPT.freeze
      You screen messages that students in grades 4-12 send to a coding tutor. You do not answer them.
      Reply with exactly one line:
      OK
      or
      FLAG <category>: <short reason, under 12 words>
      Categories: distress (the student may be upset, unsafe, or at risk), harm (wants to hurt someone or do something dangerous or illegal), bullying (insults or targets a person), inappropriate (sexual or graphic content), personal_info (shares private details about a real person).
      Off-topic but harmless messages are OK; the tutor redirects those itself. Silly or frustrated messages about code are OK.
    PROMPT

    def self.call(text, grade:) = new(text, grade).call

    def initialize(text, grade)
      @text, @grade = text, grade
    end

    def call
      return flag("distress", "Possible distress (keyword match)") if @text.match?(DISTRESS)
      return ok unless Ai.live?

      response = Ai.client.messages.create(
        model: Ai::SAFETY_MODEL,
        max_tokens: 60,
        system_: SYSTEM,
        messages: [ { role: "user", content: "Grade #{@grade} student message:\n<<<\n#{@text}\n>>>" } ]
      )
      line = response.content.select { |b| b.type == :text }.map(&:text).join.strip
      if (m = line.match(/\AFLAG\s+(\w+):\s*(.+)\z/))
        flag(m[1], m[2])
      else
        ok
      end
    rescue Anthropic::Errors::APIError => e
      Rails.logger.warn("[Ai::SafetyCheck] #{e.class}: #{e.message}")
      ok # The keyword pass already ran; the tutor prompt has its own safety rules.
    end

    private
      def ok = Result.new(flagged: false)

      def flag(category, reason)
        Result.new(flagged: true, category:, reason:, severity: URGENT.include?(category) ? "urgent" : "review")
      end
  end
end
