# Everything Launchpad stores about a student, for a parent's "download my child's data" request.
class StudentExport
  def initialize(student)
    @student = student
  end

  def as_json(*)
    {
      exported_at: Time.current,
      student: @student.slice(:name, :username, :grade, :birth_year, :created_at, :last_active_at),
      parent_consent: @student.parent_consent&.slice(:parent_name, :parent_email, :status, :account_consent, :ai_consent,
                                                     :signature_name, :submitted_at, :verified_at, :verification_method, :notice_version),
      classes: @student.classrooms.map { |c| { name: c.name, teacher: c.teacher.name } },
      milestones_passed: @student.skill_checks.includes(:milestone).map { |c| { milestone: c.milestone.description, checked_at: c.created_at } },
      projects: @student.projects.includes(:versions).map do |p|
        { title: p.title, spec: p.spec, ruby_code: p.ruby_source, created_at: p.created_at, updated_at: p.updated_at,
          saved_versions: p.versions.map { |v| { author: v.author, saved_at: v.created_at, ruby_code: v.ruby_source } } }
      end,
      help_requests: @student.help_sessions.includes(:steps).map do |h|
        { card: h.description, status: h.status, created_at: h.created_at,
          steps: h.steps.map { |s| { level: s.level, coach: s.response_text, choices: s.choices, student_pressed: s.kid_choice, source: s.model } } }
      end,
      typed_questions: @student.ai_interactions.where(help_session_id: nil).map do |i|
        { asked: i.prompt, answer: i.response_text, status: i.status, created_at: i.created_at }
      end,
      grades: ProjectReview.returned.joins(:project).where(projects: { student_id: @student.id }).includes(:project).map do |r|
        { project: r.project.title, coding: r.coding, problem_solving: r.problem_solving, made_it_yours: r.ownership, feedback: r.feedback, returned_at: r.returned_at }
      end,
      messages: Array(@student.message_thread&.messages&.includes(:author)).map { |m| { from: m.author.name, at: m.created_at, message: m.body } },
      sign_ins: @student.sessions.map { |s| { at: s.created_at, ip_address: s.ip_address, browser: s.user_agent } }
    }
  end

  def to_json(*) = JSON.pretty_generate(as_json)
end
