class Stage < ApplicationRecord
  AI_MODES = %w[hint explain fix build chat].freeze
  EDITORS = %w[blocks split ruby_first ruby].freeze

  has_many :milestones, -> { order(:position) }, dependent: :destroy
  has_many :projects

  validates :key, :name, :grades, :tool, :coding_focus, :ai_focus, :computer_focus, :project_summary, presence: true
  validates :editor, inclusion: { in: EDITORS }

  scope :ordered, -> { order(:position) }

  def self.for_grade(grade)
    ordered.find { |s| grade.between?(s.min_grade, s.max_grade) } || ordered.first
  end

  def next_stage = Stage.where("position > ?", position).ordered.first

  # Blocks are the main surface for the early stages; Ruby takes over from there.
  def blocks_available? = editor.in?(%w[blocks split ruby_first])
end
