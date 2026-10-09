# A project a student turned in, and the teacher's grade when it comes back.
class ProjectReview < ApplicationRecord
  CRITERIA = {
    "coding" => { name: "Coding", kid: "Your code works and is easy to read." },
    "problem_solving" => { name: "Problem solving", kid: "You broke the problem into steps and fixed bugs." },
    "ownership" => { name: "Made it yours", kid: "You changed it and can explain every line." }
  }.freeze
  SCALE = { 1 => "Just starting", 2 => "Getting there", 3 => "Got it", 4 => "Wow" }.freeze

  belongs_to :project
  belongs_to :reviewer, class_name: "User", optional: true

  validates :status, inclusion: { in: %w[submitted returned] }
  validates :student_note, length: { maximum: 500 }
  validates :feedback, length: { maximum: 2000 }
  CRITERIA.each_key { |c| validates c, inclusion: { in: SCALE.keys }, if: :returned? }
  validates :feedback, presence: true, if: :returned?

  scope :waiting, -> { where(status: "submitted").order(:submitted_at) }
  scope :returned, -> { where(status: "returned") }

  def submitted? = status == "submitted"
  def returned? = status == "returned"
  def student = project.student

  def return!(by:, scores:, feedback:)
    update!(scores.slice(*CRITERIA.keys).merge(status: "returned", reviewer: by, feedback:, returned_at: Time.current))
  end
end
