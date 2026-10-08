module Ai
  TUTOR_MODEL = :"claude-opus-5-5"
  SAFETY_MODEL = :"claude-haiku-4-5"

  MODE_LABELS = {
    "hint" => "Hint", "explain" => "Explain", "fix" => "Fix my bug", "build" => "Build from my spec", "chat" => "Ask a question"
  }.freeze

  MODE_PROMPTS = {
    "hint" => "What are you stuck on?",
    "explain" => "What do you want explained? (a line, a block, or an error)",
    "fix" => "What's going wrong? What did you expect to happen?",
    "build" => "Your spec: describe what your program should do, step by step",
    "chat" => "Ask a coding, computer, or AI question"
  }.freeze

  # Returns nil when no API key is configured; the app then uses Ai::OfflineTutor so it still works in development.
  def self.client
    key = ENV["ANTHROPIC_API_KEY"].presence || Rails.application.credentials.dig(:anthropic, :api_key)
    return unless key
    @client ||= Anthropic::Client.new(api_key: key, timeout: 60)
  end

  def self.live? = client.present?
end
