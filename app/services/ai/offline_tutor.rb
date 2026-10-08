# Canned, rule-based replies used when no ANTHROPIC_API_KEY is set, so the whole flow
# (gate → safety → review → delivery → accept) can be developed and demoed offline.
module Ai
  class OfflineTutor
    def self.call(interaction) = new(interaction).call

    def initialize(interaction)
      @interaction = interaction
      @code = interaction.code_snapshot.to_s
    end

    def call
      { text: send(:"reply_#{@interaction.mode}"), model: "offline-demo", input_tokens: 0, output_tokens: 0, declined: false }
    end

    private
      def reply_hint
        if @code.strip.empty?
          "(Demo coach) Start small! What is the very first thing your sprite should do? Try one move block, then run it."
        elsif !@code.include?("times")
          "(Demo coach) Are you repeating the same lines more than once? Which lines could go inside a repeat (times) loop?"
        else
          "(Demo coach) Run your program and watch closely. What does the sprite do that you didn't expect? Which line makes that happen?"
        end
      end

      def reply_explain
        line = @code.lines.map(&:strip).reject { |l| l.empty? || l.start_with?("#") }.first
        return "(Demo coach) Your project is empty, so there's nothing to explain yet. Add a block and ask again!" unless line
        "(Demo coach) Let's look at `#{line}`. The part before the dot is WHO does something, and the part after the dot is WHAT they do. The number in parentheses is HOW MUCH. What do you think happens if you change that number?"
      end

      def reply_fix
        if @code.scan(/\bdo\b/).size > @code.scan(/\bend\b/).size
          "(Demo coach) Every `do` needs a matching `end`. Count them in your code. Is one missing?"
        else
          "(Demo coach) Read your code one line at a time and say out loud what the sprite should do. Where does what you say stop matching what you see?"
        end
      end

      def reply_build
        spec = @interaction.prompt.downcase
        sprite = %w[rocket dog star cat].find { |s| spec.include?(s) } || "cat"
        <<~TXT
          (Demo coach) Here's a starting point: the #{sprite} moves in a square and talks.

          ```ruby
          background("#{spec.include?('space') ? 'space' : 'sky'}")
          #{sprite}.say("Here I go!")
          wait(1)
          4.times do
            #{sprite}.move(100)
            #{sprite}.turn(90)
            wait(0.2)
          end
          #{sprite}.say("Done!")
          ```

          Test it: does the #{sprite} end up where it started? Then make it your own: change the square into a triangle.
        TXT
      end

      def reply_chat
        "(Demo coach) Good question! Connect your API key to get real answers. For now: try it out in your project and see what happens — testing is how coders find out."
      end
  end
end
