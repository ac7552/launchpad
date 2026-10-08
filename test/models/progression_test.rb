require "test_helper"

class ProgressionTest < ActiveSupport::TestCase
  test "students move up a stage only after passing every milestone" do
    teacher = create_teacher
    student = create_student(grade: 4)
    assert_equal "g4", student.current_stage.key

    g4 = Stage.find_by!(key: "g4")
    g4.milestones.each { |m| student.skill_checks.create!(milestone: m, checked_by: teacher) }
    assert_equal "g5", student.reload.current_stage.key
  end

  test "only students 13+ in a green class may type to the AI" do
    classroom = create_classroom(light: "green")
    twelve = create_student("twelve", grade: 7, classroom:, age: 12)
    fourteen = create_student("fourteen", grade: 9, classroom:, age: 14)
    policy = classroom.policy

    assert_not twelve.typing_allowed?
    assert_empty policy.modes_for(twelve)
    assert_equal %w[hint explain fix build chat], policy.modes_for(fourteen)

    policy.update!(allowed_modes: %w[hint chat])
    assert_equal %w[hint chat], policy.modes_for(fourteen)

    policy.update!(light: "yellow")
    assert_empty policy.modes_for(fourteen)
  end

  test "a missing birth year never counts as 13+" do
    student = create_student("unknown", grade: 9)
    student.update_column(:birth_year, nil)
    assert_not student.reload.typing_allowed?
  end
end
