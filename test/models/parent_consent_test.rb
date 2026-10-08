require "test_helper"

class ParentConsentTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @teacher = create_teacher
    @classroom = create_classroom(@teacher)
  end

  test "under-13 students can't sign in until a parent consents and staff verify" do
    student = create_student(grade: 4, age: 9, classroom: @classroom, consent: :requested)
    assert student.consent_required?
    assert_not student.can_sign_in?

    student.parent_consent.submit!(signature_name: "Pat Rivera", ai_consent: false, ip: "1.2.3.4")
    assert_not student.reload.can_sign_in?, "a parent's online signature alone isn't verified consent"

    student.parent_consent.verify!(by: @teacher, method: "signed_form_in_person")
    assert student.reload.can_sign_in?
    assert_not student.ai_sharing_allowed?, "the AI coach is a separate consent"
  end

  test "teens don't need parent consent" do
    teen = create_student("teen", grade: 9, age: 14)
    assert_not teen.consent_required?
    assert teen.can_sign_in?
    assert teen.ai_sharing_allowed?
  end

  test "turning the AI coach on later needs staff verification; turning it off is instant" do
    student = create_student(grade: 5, age: 10, classroom: @classroom, consent: :verified_no_ai)
    consent = student.parent_consent
    policy = @classroom.policy

    consent.set_ai_consent!(true)
    assert consent.ai_pending?
    assert_not student.reload.ai_sharing_allowed?

    consent.verify!(by: @teacher, method: "video_call")
    assert student.reload.ai_sharing_allowed?

    consent.set_ai_consent!(false)
    assert_not student.reload.ai_sharing_allowed?
    begin
      with_fake_claude { assert_equal "bank", policy.hint_source_for(student) }
    end
  end

  test "students are stored as first name and last initial" do
    student = create_student(grade: 9, age: 14)
    assert_equal "Sam R.", student.name
  end

  test "erasing a student removes their data and keeps a record without personal info" do
    student = create_student(grade: 4, age: 9, classroom: @classroom)
    project = student.projects.create!(title: "Game")
    project.apply_source!("cat.move(10)\n", author: "kid")
    Ai::Guide.start(student:, project:, card: "repeat")

    deletion = DataDeletion.erase!(student, reason: "parent_request")
    assert_not User.exists?(student.id)
    assert_equal 0, Project.where(id: project.id).count
    assert_equal 0, HelpSession.where(student_id: student.id).count
    assert_equal({ "projects" => 1, "ai_interactions" => 1, "help_sessions" => 1 }, deletion.counts)
    assert_not_includes deletion.attributes.values.map(&:to_s).join(" "), "Sam"
  end

  test "the retention job deletes unanswered requests, inactive accounts, and old AI logs" do
    waiting = create_student("waiting", grade: 4, age: 9, classroom: @classroom, consent: :requested)
    fresh = create_student("fresh", grade: 4, age: 9, classroom: @classroom, consent: :requested)
    active = create_student("active", grade: 4, age: 9, classroom: @classroom)
    idle = create_student("idle", grade: 9, age: 14, classroom: @classroom)
    waiting.parent_consent.update!(requested_at: 15.days.ago)
    idle.update_columns(last_active_at: 400.days.ago, created_at: 400.days.ago)
    active.update_column(:last_active_at, 1.day.ago)
    project = active.projects.create!(title: "Game")
    old_session = Ai::Guide.start(student: active, project:, card: "repeat")
    old_session.update_column(:created_at, 400.days.ago)

    PurgeExpiredDataJob.perform_now

    assert_not User.exists?(waiting.id)
    assert_not User.exists?(idle.id)
    assert User.exists?(fresh.id)
    assert User.exists?(active.id)
    assert_not HelpSession.exists?(old_session.id)
    assert_equal %w[consent_expired inactive], DataDeletion.order(:id).pluck(:reason)
  end
end
