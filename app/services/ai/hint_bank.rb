# Pre-written hints for every card and level. Used when a class is on red (no AI), when no API
# key is configured, and as the fallback whenever an AI reply fails validation.
module Ai
  class HintBank
    MODEL = "hint-bank".freeze

    def self.step(session, level) = new(session).step(level)

    def initialize(session)
      @session = session
      @blocks = session.project.editor_mode.in?(%w[blocks split])
      @code = session.project.ruby_source.to_s
    end

    def step(level)
      answer = @session.steps.find_by(level: 1)&.kid_choice
      send(:"#{@session.card}_#{level}", answer).then do |text, choices = []|
        { text:, choices:, line: pointer_line(level) }
      end
    end

    private
      def thing = @blocks ? "block" : "line"

      def pointer_line(level)
        return @session.line_number if @session.line_number
        return error_line if @session.card == "error"
        level == 2 ? first_line_matching(@session.card == "repeat" ? /move|turn/ : /\S/) : nil
      end

      def error_line = @session.error_text.to_s[/line (\d+)/, 1]&.to_i

      def first_line_matching(pattern)
        index = @code.lines.index { |l| l.match?(pattern) && !l.strip.start_with?("#") }
        index && index + 1
      end

      # 🤔 It's doing the wrong thing
      def not_expected_1(_) = [ "Run it and watch. What goes wrong first?",
                                [ "It goes the wrong way", "It goes too far", "Things are out of order", "Nothing happens" ] ]

      def not_expected_2(answer)
        case answer
        when /wrong way/ then "Look at your turn #{thing}s. Plain numbers turn right. Minus numbers turn left. Which turn comes first?"
        when /too far/ then "Look at the numbers in your move #{thing}s. Try a smaller number. Then run it."
        when /order/ then "The computer reads top to bottom. Read your code out loud. Where does it go wrong?"
        when /Nothing/ then "Do you have a move, turn, or say #{thing}? Are all your #{thing}s connected?"
        else "Read your code one #{thing} at a time. Where does it stop matching what you see?"
        end
      end

      def not_expected_3(_)
        @blocks ? "Try this: change just ONE number. Run it. Watch what changes." :
                  "Try this: change ONE number, like `cat.turn(90)` to `cat.turn(-90)`. Run it. What changed?"
      end

      # 🔍 What does this line do?
      def explain_line_1(_) = [ "Look at line #{@session.line_number}: `#{@session.line_text.to_s.strip}`. What do you think it does?",
                                [ "It moves or turns", "It repeats", "It shows words", "I'm not sure" ] ]

      def explain_line_2(_)
        line = @session.line_text.to_s
        meaning =
          case line
          when /\.move/ then "moves the sprite. The number is how many steps."
          when /\.turn/ then "turns the sprite. 90 is a quarter turn."
          when /\.go_to/ then "jumps the sprite to a spot. First number: left or right. Second number: up or down."
          when /\.say/ then "makes a speech bubble."
          when /\.times do/ then "repeats. The lines down to `end` run that many times."
          when /\A\s*if/ then "asks a question. The lines inside only run if the answer is yes."
          when /\A\s*end/ then "ends the loop or if above it."
          when /wait/ then "waits that many seconds."
          when /background/ then "changes the picture in the back."
          when /puts|print/ then "prints words in the box under the stage."
          else "tells the computer to do one thing. Before the dot is WHO. After the dot is WHAT."
          end
        "This line #{meaning} Change it a little and run it. What changed?"
      end

      def explain_line_3(_) = "Try this: copy the line. Change the copy. Run it. Then delete the copy."

      # 🔁 How do I repeat?
      def repeat_1(_) = [ "What should happen more than once?", [ "Moving", "Turning", "Talking", "I'm not sure" ] ]

      def repeat_2(_)
        @blocks ? "Find blocks that are the same. Put them inside a repeat block. It's in Control." :
                  "Find lines that are the same. You can put them inside a loop and write them just once."
      end

      def repeat_3(_)
        @blocks ? "Example: repeat 4 times: move 50, turn 90. That makes a square! What does repeat 3 with turn 120 make?" :
                  "Example: `3.times do` … `end`. The lines in between run 3 times."
      end

      # ⚠️ I see an error
      def error_1(_) = [ "Read the red words under the stage. What do they say?",
                         [ "A line number", "A word is wrong", "Something is missing", "I don't see red words" ] ]

      def error_2(_)
        error = @session.error_text.to_s
        line = error_line
        where = line ? "Go to line #{line}." : "Look near the end of your code."
        if error.match?(/Ruby couldn't read this|syntax/i)
          "#{where} Count your `do`s and `end`s. Each `do` needs an `end`."
        elsif error.match?(/doesn't know|spelling|undefined/i)
          "#{where} Check the spelling. One wrong letter can break it."
        else
          "#{where} Read that line slowly. Which part looks wrong?"
        end
      end

      def error_3(_) = "Example: `cat.mvoe(10)` is broken. `cat.move(10)` works. Spelling matters!"

      # 💡 What can I add?
      def next_idea_1(_) = [ "What would make it more fun?",
                             [ "More talking", "A new shape", "Another sprite", "A new background" ] ]

      def next_idea_2(answer)
        case answer
        when /talk/ then "When should your sprite talk? Add a say #{thing} right there."
        when /shape/ then "A square turns 90 each time. A triangle turns 120. Try it!"
        when /sprite/ then "Try dog, rocket, or star. What could it do?"
        when /background/ then "Try sky, grass, night, space, or sand. Put it at the top."
        else "Look at your plan. What is one thing your game doesn't do yet?"
        end
      end

      def next_idea_3(_) = "Example: `rocket.say(\"3, 2, 1!\")` then `rocket.move(150)`. Blast off! Can you add a moment like that?"
  end
end
