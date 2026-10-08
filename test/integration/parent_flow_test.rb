require "test_helper"

class ParentFlowTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @teacher = create_teacher
    @classroom = create_classroom(@teacher)
  end

  def sign_in(user)
    post session_path, params: { username: user.username, password: "secret-pass" }
  end

  test "teacher adds an under-13 student, parent consents, teacher verifies, student signs in" do
    sign_in @teacher
    assert_enqueued_emails 1 do
      post teach_classroom_students_path(@classroom), params: {
        user: { name: "Lena Marsh", username: "lena", grade: 4, birth_year: Date.current.year - 10, password: "secret-pass" },
        parent: { name: "Rae Marsh", email: "rae@example.com" }
      }
    end
    student = User.find_by!(username: "lena")
    assert_equal "Lena M.", student.name
    consent = student.parent_consent

    delete session_path
    sign_in student
    assert_redirected_to new_session_path
    follow_redirect!
    assert_match "waiting for a parent", response.body

    get parent_consent_path(consent.token)
    assert_select ".notice-ai h2", text: "AI coach"
    post parent_submit_path(consent.token), params: { account_consent: "1", ai_consent: "1", guardian: "1", signature_name: "Rae Marsh" }
    assert consent.reload.submitted?
    assert consent.submitted_ip.present?, "we keep a record of where the signature came from"

    sign_in @teacher
    post verify_teach_student_consent_path(student), params: { verification_method: "signed_form_in_person", attest: "1" }
    assert consent.reload.verified?
    assert consent.ai_allowed?

    delete session_path
    sign_in student
    assert_redirected_to root_url
  end

  test "an under-13 student can't be added without a parent" do
    sign_in @teacher
    post teach_classroom_students_path(@classroom), params: {
      user: { name: "Lena Marsh", username: "lena", grade: 4, birth_year: Date.current.year - 10, password: "secret-pass" }
    }
    assert_response :unprocessable_entity
    assert_not User.exists?(username: "lena")
  end

  test "parents can download and delete their child's data, and revoking ends the child's session" do
    student = create_student(grade: 4, age: 9, classroom: @classroom)
    student.projects.create!(title: "Rocket")
    consent = student.parent_consent

    sign_in student
    get root_path
    assert_response :success

    get parent_export_path(consent.token)
    data = JSON.parse(response.body)
    assert_equal "Rocket", data["projects"].first["title"]
    assert_equal "Sam R.", data["student"]["name"]

    consent.update!(status: "revoked")
    get root_path
    assert_redirected_to new_session_path

    delete parent_erase_path(consent.token)
    assert_not User.exists?(student.id)
    assert_equal "parent_request", DataDeletion.last.reason
    get parent_consent_path(consent.token)
    assert_response :not_found
  end

  test "declining deletes the account" do
    student = create_student(grade: 4, age: 9, classroom: @classroom, consent: :requested)
    post parent_decline_path(student.parent_consent.token)
    assert_not User.exists?(student.id)
    assert_equal "parent_declined", DataDeletion.last.reason
  end

  test "the privacy page is public, and keeps the nav for signed-in people" do
    get privacy_path
    assert_response :success
    assert_select "h1", "Privacy"
    assert_select ".topbar", 0

    sign_in @teacher
    get privacy_path
    assert_select ".topbar .menu-toggle"
  end
end
