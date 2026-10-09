require "test_helper"

class TeacherFlowTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = create_teacher
    @classroom = create_classroom(@teacher)
    @student = create_student(grade: 4, classroom: @classroom)
    @project = @student.projects.create!(title: "Game")
  end

  def sign_in(user)
    post session_path, params: { username: user.username, password: "secret-pass" }
  end

  test "teacher sets AI rules, approves a held answer, and checks off a milestone" do
    sign_in @teacher
    patch teach_classroom_ai_policy_path(@classroom), params: { ai_policy: { light: "red", review_required: "1", daily_limit: 5, allowed_modes: [ "hint" ] } }
    assert @classroom.policy.reload.review_required?
    assert @classroom.policy.red?
    assert_equal [ "hint" ], @classroom.policy.allowed_modes

    held = AiInteraction.create!(student: @student, project: @project, classroom: @classroom, mode: "hint",
                                 prompt: "help", status: "held", response_text: "Try a loop!")
    get teach_reviews_path
    assert_select ".review-card", 1
    post approve_teach_review_path(held)
    assert held.reload.delivered?
    assert_equal @teacher, held.reviewed_by

    milestone = Stage.find_by!(key: "g4").milestones.first
    post teach_student_skill_checks_path(@student, milestone_id: milestone.id)
    assert @student.skill_checks.exists?(milestone:)
  end

  test "teachers only see their own students" do
    other_teacher = create_teacher("other")
    sign_in other_teacher
    get teach_student_path(@student)
    assert_response :not_found
  end

  test "students can't open teacher pages or other students' projects" do
    sign_in @student
    get teach_reviews_path
    assert_redirected_to root_path

    classmate = create_student("pal", grade: 4, classroom: @classroom)
    sign_in classmate
    get project_path(@project)
    assert_response :not_found
  end

  test "a student picks a question card and climbs the hint ladder" do
    sign_in @student
    post project_help_sessions_path(@project), params: { card: "repeat", ruby_source: "cat.move(10)\ncat.move(10)\n" }, as: :turbo_stream
    assert_response :success
    session = @student.help_sessions.last
    assert_equal "cat.move(10)\ncat.move(10)\n", @project.reload.ruby_source
    assert_equal 1, session.steps.count
    assert_select "button", text: "Moving"

    post respond_help_session_path(session), params: { choice: "Moving" }, as: :turbo_stream
    assert_equal 2, session.reload.level
    assert_select "button", text: /It worked!/
  end

  test "only 13+ students in a green class see the typed-question box" do
    @classroom.policy.update!(light: "green")
    teen = create_student("teen", grade: 9, classroom: @classroom, age: 14)
    teen_project = teen.projects.create!(title: "Teen game")

    sign_in @student
    get project_path(@project)
    assert_select ".question-card", Ai::Cards.keys.size
    assert_select ".typed-questions", 0

    sign_in teen
    get project_path(teen_project)
    assert_select ".typed-questions", 1
  end

  test "red classes show the hint helper without AI wording" do
    @classroom.policy.update!(light: "red")
    sign_in @student
    get project_path(@project)
    assert_select ".coach-head", text: /Hints/
    assert_select ".ai-about", 0
  end

  test "students see the path and a tap-to-open list of levels" do
    sign_in @student
    get path_path
    assert_select ".path .node", Stage.count
    assert_select ".level h2", @student.current_stage.kid_name

    get curriculum_path(level: "g6")
    assert_select "details.level-row", Stage.count
    assert_select "details.level-row[open] .level-row-name", "Ruby First"
    assert_select "details.level-row[open] .goal", Stage.find_by!(key: "g6").milestones.count
  end

  test "teachers see the detailed curriculum" do
    sign_in @teacher
    get curriculum_path
    assert_select "details.level-row", Stage.count
    assert_select ".three-cols", Stage.count
  end

  test "the world is home, with places that lead to each part of the app" do
    sign_in @student
    get root_path
    assert_select ".spot", 6
    assert_select "template[data-spot=workshop]"
    assert_select ".world-strip button", 6

    sign_in @teacher
    get root_path
    assert_select ".spot", 6
    assert_select ".spot-label", text: /Review/
  end
end
