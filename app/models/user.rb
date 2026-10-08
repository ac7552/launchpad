class User < ApplicationRecord
  ROLES = %w[student teacher admin].freeze

  has_secure_password
  has_many :sessions, dependent: :destroy

  # Teacher side
  has_many :taught_classrooms, class_name: "Classroom", foreign_key: :teacher_id, dependent: :destroy

  # Student side
  has_many :enrollments, foreign_key: :student_id, dependent: :destroy
  has_many :classrooms, through: :enrollments
  has_many :projects, foreign_key: :student_id, dependent: :destroy
  has_many :skill_checks, foreign_key: :student_id, dependent: :destroy
  has_many :ai_interactions, foreign_key: :student_id, dependent: :destroy
  has_many :help_sessions, foreign_key: :student_id, dependent: :destroy
  has_one :parent_consent, foreign_key: :student_id, dependent: :destroy

  normalizes :username, with: ->(u) { u.strip.downcase }

  # Data minimization: students are stored as first name + last initial ("Maya L.").
  before_validation :shorten_student_name, if: :student?

  validates :name, presence: true
  validates :username, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_.\-]+\z/, message: "can use letters, numbers, dots, dashes and underscores" }
  validates :role, inclusion: { in: ROLES }
  validates :grade, inclusion: { in: 4..12 }, if: :student?
  validates :birth_year, presence: true, numericality: { only_integer: true, in: 1990..Date.current.year }, if: :student?

  scope :students, -> { where(role: "student") }

  ROLES.each { |r| define_method(:"#{r}?") { role == r } }

  def staff? = teacher? || admin?

  def first_name = name.split.first

  # Youngest the student could be, since only the birth year is stored. Unknown counts as under 13.
  def minimum_age = birth_year ? Date.current.year - birth_year - 1 : 0

  # COPPA line and AI providers' age rules: only students 13+ may type to the AI.
  def typing_allowed? = student? && minimum_age >= 13

  # Under 13 (or unknown age): a parent must consent, and staff must verify it, before the child can use Launchpad.
  def consent_required? = student? && minimum_age < 13
  def can_sign_in? = !consent_required? || parent_consent&.account_allowed?

  # Whether this student's project data may be sent to the AI provider.
  def ai_sharing_allowed? = !consent_required? || parent_consent&.ai_allowed?

  # The student's current stage: the lowest stage at or above their grade's starting point
  # whose milestones are not all passed. Students move up by passing milestones, not by grade alone.
  def current_stage
    return unless student?
    @current_stage ||= begin
      passed = skill_checks.pluck(:milestone_id).to_set
      start = Stage.for_grade(grade)
      Stage.where("position >= ?", start.position).ordered.includes(:milestones)
           .find { |stage| !stage.milestones.all? { |m| passed.include?(m.id) } } || Stage.ordered.last
    end
  end

  def reload(*)
    @current_stage = nil
    super
  end

  # Each guided session counts once (however many hint steps it takes); each typed question counts once.
  def ai_requests_today
    today = Time.current.all_day
    help_sessions.where(created_at: today).count +
      ai_interactions.where(created_at: today, help_session_id: nil).where.not(status: "denied").count
  end

  def primary_classroom = classrooms.order(:created_at).first

  private
    def shorten_student_name
      first, *rest = name.to_s.split
      self.name = [ first, (rest.last && "#{rest.last[0].upcase}.") ].compact.join(" ")
    end
end
