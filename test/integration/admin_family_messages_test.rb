require "test_helper"

class AdminFamilyMessagesTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @teacher = create_teacher
    @classroom = create_classroom(@teacher)
    @student = create_student("kid", grade: 5, age: 10, classroom: @classroom)
    @project = @student.projects.create!(title: "Rocket")
    @project.apply_source!("rocket.move(10)\n", author: "kid")
  end

  def sign_in(user, password: "secret-pass")
    delete session_path if cookies[:session_id].present?
    post session_path, params: { username: user.username, password: }
  end

  test "staff set tiers one at a time and in bulk, and tiers never change permissions" do
    other = create_student("other", grade: 8, age: 13, classroom: @classroom)
    sign_in @teacher

    get teach_students_path
    assert_select "td a", text: @student.name

    patch teach_student_path(@student), params: { tier: "launch_crew" }
    assert_equal "launch_crew", @student.reload.tier
    assert_not @student.typing_allowed?, "a tier never unlocks typing to the AI"

    post bulk_tier_teach_students_path, params: { student_ids: [ @student.id, other.id ], tier: "" }
    assert_equal "explorer", @student.reload.tier
    assert_equal "builder", other.reload.tier
  end

  test "a student turns in a project and the teacher grades it" do
    sign_in @student
    post turn_in_project_path(@project), params: { note: "it flies!" }
    review = @project.open_review
    assert_equal "it flies!", review.student_note

    sign_in @teacher
    get teach_grading_index_path
    assert_select ".row-name", text: "Rocket"
    patch teach_project_review_path(review), params: { project_review: { coding: 3, problem_solving: 4, feedback: "" } }
    assert review.reload.submitted?, "needs all three scores and feedback"

    patch teach_project_review_path(review), params: { project_review: { coding: 3, problem_solving: 4, ownership: 2, feedback: "Great loop! Now change the turn." } }
    assert review.reload.returned?

    sign_in @student
    get project_path(@project)
    assert_select ".feedback-card", text: /Great loop/
  end

  test "a parent is invited, makes a login, and sees only their own child" do
    sign_in @teacher
    assert_enqueued_emails 1 do
      post teach_student_guardianships_path(@student), params: { guardianship: { name: "Rae", email: "rae@example.com" } }
    end
    guardianship = @student.guardianships.find_by!(email: "rae@example.com")
    delete session_path

    post join_path(guardianship.token), params: { name: "Rae M", password: "longenough1", password_confirmation: "longenough1" }
    parent = User.find_by!(username: "rae@example.com")
    assert parent.parent?
    assert_redirected_to family_child_path(@student)

    follow_redirect!
    assert_select "h1", @student.name
    get family_project_path(@student, @project)
    assert_select "pre.code", text: /rocket.move/

    stranger = create_student("stranger", grade: 5, age: 10, classroom: @classroom)
    get family_child_path(stranger)
    assert_response :not_found
    get project_path(@project)
    assert_redirected_to root_path
  end

  test "the family thread is shared by the student, their parents, and their teachers only" do
    parent = User.create!(role: "parent", username: "pat@example.com", name: "Pat", password: "secret-pass")
    @student.guardianships.create!(name: "Pat", email: "pat@example.com").claim!(parent)

    sign_in @student
    post message_thread_path(@student), params: { body: "I'm stuck on my loop" }
    assert_equal 1, @student.message_thread.messages.count
    assert_equal 0, AiInteraction.count, "messages never go to the AI"

    sign_in parent
    get message_thread_path(@student)
    assert_select ".msg-body", text: "I'm stuck on my loop"

    sign_in @teacher
    get messages_path
    assert_select ".thread-list strong", text: @student.name
    post message_thread_path(@student), params: { body: "Let's look together tomorrow." }

    outsider = create_teacher("outsider")
    sign_in outsider
    get message_thread_path(@student)
    assert_response :not_found
  end

  test "possible distress in a student's message is flagged for staff" do
    sign_in @student
    post message_thread_path(@student), params: { body: "i want to hurt myself" }
    assert @student.message_thread.messages.last.urgent?
  end

  test "deleting a student removes their messages, grades, and parent links" do
    parent = User.create!(role: "parent", username: "pat@example.com", name: "Pat", password: "secret-pass")
    @student.guardianships.create!(name: "Pat", email: "pat@example.com").claim!(parent)
    MessageThread.for(@student).messages.create!(author: @student, body: "hi")
    @project.turn_in!

    DataDeletion.erase!(@student, reason: "parent_request")
    assert_equal 0, Message.count
    assert_equal 0, ProjectReview.count
    assert_equal 0, Guardianship.count
    assert User.exists?(parent.id), "the parent's own login stays until they ask to delete it"
  end
end
