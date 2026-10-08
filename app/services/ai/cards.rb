# The questions students can pick instead of typing. Every guided help session starts from one.
module Ai
  module Cards
    ALL = {
      "not_expected" => { emoji: "🤔", label: "It's doing the wrong thing", needs_line: false },
      "explain_line" => { emoji: "🔍", label: "What does this line do?", needs_line: true },
      "repeat" => { emoji: "🔁", label: "How do I repeat?", needs_line: false },
      "error" => { emoji: "⚠️", label: "I see an error", needs_line: false },
      "next_idea" => { emoji: "💡", label: "What can I add?", needs_line: false }
    }.freeze

    def self.keys = ALL.keys
    def self.fetch(key) = ALL.fetch(key)
    def self.each(&) = ALL.each(&)
  end
end
