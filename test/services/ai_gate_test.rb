require "test_helper"

class AiGateTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @classroom = create_classroom(light: "green")
    @student = create_student(grade: 9, classroom: @classroom, age: 14)
    @classmate = create_student("pal", grade: 9, classroom: @classroom).tap { |s| s.update!(name: "Jordan Lee") }
    @project = @student.projects.create!(title: "Game")
  end

  test "scrubs personal info and queues allowed requests" do
    interaction = nil
    assert_enqueued_with(job: AiTutorJob) do
      interaction = Ai::Gate.call(student: @student, project: @project, mode: "hint",
                                  prompt: "Jordan says email jordan@example.com or call 555-123-4567")
    end
    assert interaction.pending?
    assert_equal "[name] says email [email removed] or call [phone removed]", interaction.prompt
    assert_equal "info", interaction.flag_severity
  end

  test "students under 13 can never type to the AI, even in a green class" do
    young = create_student("young", grade: 7, classroom: @classroom, age: 12)
    project = young.projects.create!(title: "Game")
    interaction = Ai::Gate.call(student: young, project:, mode: "hint", prompt: "how do loops work")
    assert interaction.denied?
    assert_match "13 and older", interaction.response_text
    assert_no_enqueued_jobs
  end

  test "denies typed questions unless the class is green, and after the daily limit" do
    @classroom.policy.update!(light: "yellow")
    assert Ai::Gate.call(student: @student, project: @project, mode: "hint", prompt: "help me").denied?

    @classroom.policy.update!(light: "green", daily_limit: 1)
    assert Ai::Gate.call(student: @student, project: @project, mode: "hint", prompt: "help me").pending?
    assert Ai::Gate.call(student: @student, project: @project, mode: "hint", prompt: "help again").denied?
  end
end
