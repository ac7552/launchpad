require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  setup do
    @student = create_student(classroom: create_classroom)
    @project = @student.projects.create!(title: "Test")
  end

  test "takes the editor from the student's stage" do
    assert_equal "split", @project.editor_mode
    assert_equal "g5", @project.stage.key
  end

  test "lines keep their author until someone changes them" do
    @project.apply_source!("cat.move(10)\n", author: "kid")
    @project.apply_source!("cat.move(10)\n3.times do\n  cat.turn(90)\nend\n", author: "ai")
    assert_equal %w[kid ai ai ai], @project.authorship
    assert @project.needs_hand_edit?

    @project.apply_source!("cat.move(10)\n4.times do\n  cat.turn(90)\nend\n", author: "kid")
    assert_equal %w[kid kid ai ai], @project.authorship
    assert_not @project.needs_hand_edit?
    assert_equal 50, @project.kid_share
    assert_equal %w[kid ai kid], @project.versions.pluck(:author)
  end

  test "saving identical code creates no version" do
    @project.apply_source!("cat.move(10)\n", author: "kid")
    assert_not @project.apply_source!("cat.move(10)\n", author: "kid")
    assert_equal 1, @project.versions.count
  end
end
