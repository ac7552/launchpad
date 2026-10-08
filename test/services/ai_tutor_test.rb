require "test_helper"

# Runs with no API key, so the offline tutor answers and the keyword safety pass applies.
class AiTutorTest < ActiveSupport::TestCase
  setup do
    @classroom = create_classroom(light: "green")
    @student = create_student(grade: 9, classroom: @classroom, age: 14)
    @project = @student.projects.create!(title: "Game")
  end

  def interaction(mode:, prompt:)
    AiInteraction.create!(student: @student, project: @project, classroom: @classroom, mode:, prompt:, code_snapshot: "")
  end

  test "build mode delivers a code proposal" do
    i = interaction(mode: "build", prompt: "a rocket flies in a square")
    Ai::Tutor.call(i)
    assert i.reload.delivered?
    assert_includes i.proposed_code, "rocket.move"
    assert_equal "open", i.proposal_state
  end

  test "answers wait for the teacher when review is required" do
    @classroom.policy.update!(review_required: true)
    i = interaction(mode: "hint", prompt: "how do loops work")
    Ai::Tutor.call(i)
    assert i.reload.held?
    assert_includes AiInteraction.needs_review, i
  end

  test "possible distress is flagged as urgent and the student is pointed to an adult" do
    i = interaction(mode: "hint", prompt: "i want to hurt myself")
    Ai::Tutor.call(i)
    assert i.reload.flagged?
    assert_equal "urgent", i.flag_severity
    assert_match "adult you trust", i.response_text
  end
end
