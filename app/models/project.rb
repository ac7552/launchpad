class Project < ApplicationRecord
  AUTHORS = %w[kid ai].freeze

  belongs_to :student, class_name: "User"
  belongs_to :classroom, optional: true
  belongs_to :stage
  has_many :versions, -> { order(:created_at) }, class_name: "ProjectVersion", dependent: :destroy
  has_many :ai_interactions, -> { order(:created_at) }, dependent: :destroy
  has_many :help_sessions, -> { order(:created_at) }, dependent: :destroy

  validates :title, presence: true, length: { maximum: 80 }
  validates :editor_mode, inclusion: { in: Stage::EDITORS }

  before_validation :set_defaults, on: :create

  # Saves new code and tracks who wrote each line. Lines that already existed keep their
  # author; new or changed lines belong to whoever made this save.
  def apply_source!(source, author:, blocks_json: nil)
    raise ArgumentError, "unknown author #{author}" unless author.in?(AUTHORS)
    source = source.to_s.gsub("\r\n", "\n")
    return false if source == ruby_source && (blocks_json.nil? || blocks_json == self.blocks_json)

    transaction do
      had_ai_code = authorship.include?("ai")
      self.authorship = attribute_lines(source, author)
      self.ruby_source = source
      self.blocks_json = blocks_json unless blocks_json.nil?
      self.hand_edits_after_ai += 1 if author == "kid" && had_ai_code
      save!
      versions.create!(author:, ruby_source: source, blocks_json: self.blocks_json)
    end
    true
  end

  def line_counts
    counted = authorship.each_with_index.reject { |_, i| ruby_source.lines[i].to_s.strip.empty? }.map(&:first)
    { kid: counted.count("kid"), ai: counted.count("ai") }
  end

  def kid_share
    counts = line_counts
    total = counts.values.sum
    total.zero? ? 100 : (counts[:kid] * 100.0 / total).round
  end

  # "Hand edits in every project": at least one meaningful change by the kid after AI wrote code.
  def needs_hand_edit? = line_counts[:ai].positive? && hand_edits_after_ai.zero?

  def blocks_in_sync? = editor_mode != "ruby" && blocks_json.present?

  private
    def set_defaults
      self.stage ||= student&.current_stage
      self.classroom ||= student&.primary_classroom
      self.editor_mode = stage&.editor || "blocks" if editor_mode.blank? || new_record?
    end

    def attribute_lines(source, author)
      pool = Hash.new { |h, k| h[k] = [] }
      ruby_source.lines.each_with_index { |line, i| pool[line.rstrip] << (authorship[i] || "kid") }
      source.lines.map { |line| pool[line.rstrip].shift || author }
    end
end
