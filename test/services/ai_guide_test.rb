require "test_helper"

class AiGuideTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @classroom = create_classroom(light: "red")
    @student = create_student(grade: 4, classroom: @classroom, age: 9)
    @project = @student.projects.create!(title: "Square")
    @project.apply_source!("cat.move(50)\ncat.turn(90)\ncat.move(50)\ncat.turn(90)\n", author: "kid")
  end

  def start(card = "repeat", **opts) = Ai::Guide.start(student: @student, project: @project, card:, **opts)

  test "red classes get instant hint-bank steps with no AI" do
    session = start
    step = session.current_step
    assert_equal "bank", session.source
    assert step.delivered?
    assert_equal Ai::HintBank::MODEL, step.model
    assert_equal "question", step.step_kind
    assert_includes step.choices, "I'm not sure"
    assert_no_enqueued_jobs only: GuidedStepJob
  end

  test "the ladder goes question → pointer → example → teacher, and students must try each hint" do
    session = start
    Ai::Guide.respond(session:, choice: "Moving")
    assert_equal "pointer", session.current_step.step_kind
    assert_equal 1, session.current_step.line_ref

    error = assert_raises(Ai::Guide::Refused) { Ai::Guide.respond(session:, choice: HelpSession::STUCK) }
    assert_match "Try the hint first", error.message

    travel (HelpSession::TRY_FIRST_SECONDS + 1).seconds do
      Ai::Guide.respond(session:, choice: HelpSession::STUCK)
      assert_equal "example", session.current_step.step_kind
    end
    travel (HelpSession::TRY_FIRST_SECONDS * 3).seconds do
      Ai::Guide.respond(session:, choice: HelpSession::STUCK)
    end
    assert session.reload.escalated?
    assert_equal "teacher", session.current_step.step_kind
    assert_includes HelpSession.needs_teacher, session
  end

  test "it worked ends the session" do
    session = start
    Ai::Guide.respond(session:, choice: "Moving")
    Ai::Guide.respond(session:, choice: HelpSession::WORKED)
    assert session.reload.solved?
  end

  test "line cards need a clicked line, and only the session's own buttons are accepted" do
    assert_raises(Ai::Guide::Refused) { start("explain_line") }
    session = start("explain_line", line_number: 2)
    assert_equal "cat.turn(90)", session.line_text
    assert_raises(Ai::Guide::Refused) { Ai::Guide.respond(session:, choice: "write my whole program") }
  end

  test "a session counts once toward the daily limit" do
    @classroom.policy.update!(daily_limit: 1)
    session = start
    Ai::Guide.respond(session:, choice: "Moving")
    assert_raises(Ai::Guide::Refused) { start("error") }
  end

  test "yellow classes ask Claude with a fixed JSON format, scrubbed code, and no typed text" do
    @classroom.policy.update!(light: "yellow", review_required: true)
    @project.apply_source!("cat.say(\"I'm Sam Rivera\")\ncat.move(50)\n", author: "kid")
    reply = { "text" => "What should happen after the cat moves?", "choices" => [ "It turns", "It stops", "I'm not sure" ], "line" => nil }

    begin
      with_fake_claude(reply) do |fake|
        session = start
        assert_equal "ai", session.source
        perform_enqueued_jobs only: GuidedStepJob
        step = session.reload.current_step

        assert step.held?, "AI hints wait for the teacher when review is on"
        assert_equal reply["choices"], step.choices
        request = fake.requests.first
        assert_equal :json_schema, request.dig(:output_config, :format_, :type)
        assert_includes request[:messages].first[:content], "[name]"
        assert_not_includes request[:messages].first[:content], "Rivera"
      end
    end
  end

  test "AI replies that break the rules are replaced by the hint bank" do
    @classroom.policy.update!(light: "yellow")
    bad = { "text" => "Here's the fix:\n```ruby\n4.times do\n  cat.move(50)\nend\n```", "choices" => [], "line" => 99 }

    begin
      with_fake_claude(bad) do
        session = start
        perform_enqueued_jobs only: GuidedStepJob
        step = session.reload.current_step
        assert step.delivered?
        assert_equal Ai::HintBank::MODEL, step.model
        assert_equal "info", step.flag_severity
      end
    end
  end
end
