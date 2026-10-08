# Removes personal information before anything is sent to an AI model or stored.
module Ai
  class Scrubber
    PATTERNS = {
      email: /\b[\w.+-]+@[\w-]+\.[\w.-]+\b/,
      phone: /(?:\+?1[\s.-]?)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}\b/,
      address: /\b\d{1,5}\s+(?:[A-Z][a-z]+\s){1,3}(?:St|Street|Ave|Avenue|Rd|Road|Blvd|Lane|Ln|Dr|Drive|Ct|Court|Way)\b\.?/,
      url: %r{\bhttps?://\S+}
    }.freeze

    Result = Struct.new(:text, :removed, keyword_init: true)

    def self.call(text, names: []) = new(names).call(text)

    def initialize(names)
      @names = names.flat_map { |n| n.to_s.split }.select { |n| n.length > 2 && n.match?(/\A[[:alpha:]'-]+\z/) }.uniq
    end

    def call(text)
      removed = []
      clean = text.to_s.strip
      PATTERNS.each do |kind, pattern|
        clean = clean.gsub(pattern) { removed << kind; "[#{kind} removed]" }
      end
      # We only store first names + last initials, so also remove a capitalized word right after a
      # known first name ("Sam Rivera" → "[name]"), which is most likely a last name.
      @names.each do |name|
        clean = clean.gsub(/\b#{Regexp.escape(name)}\b(?-i:\s+[A-Z][a-z'-]+)?/i) { removed << :name; "[name]" }
      end
      Result.new(text: clean, removed: removed.uniq)
    end
  end
end
