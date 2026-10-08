# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_10_05_180000) do
  create_table "ai_interactions", force: :cascade do |t|
    t.integer "student_id", null: false
    t.integer "project_id", null: false
    t.integer "classroom_id"
    t.string "mode", null: false
    t.text "prompt", null: false
    t.text "code_snapshot"
    t.string "status", default: "pending", null: false
    t.text "response_text"
    t.text "proposed_code"
    t.string "proposal_state"
    t.string "flag_reason"
    t.string "flag_severity"
    t.string "model"
    t.integer "input_tokens"
    t.integer "output_tokens"
    t.integer "reviewed_by_id"
    t.datetime "reviewed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "help_session_id"
    t.integer "level"
    t.string "step_kind"
    t.json "choices"
    t.integer "line_ref"
    t.string "kid_choice"
    t.datetime "delivered_at"
    t.index ["classroom_id"], name: "index_ai_interactions_on_classroom_id"
    t.index ["help_session_id"], name: "index_ai_interactions_on_help_session_id"
    t.index ["project_id"], name: "index_ai_interactions_on_project_id"
    t.index ["reviewed_by_id"], name: "index_ai_interactions_on_reviewed_by_id"
    t.index ["status"], name: "index_ai_interactions_on_status"
    t.index ["student_id", "created_at"], name: "index_ai_interactions_on_student_id_and_created_at"
    t.index ["student_id"], name: "index_ai_interactions_on_student_id"
  end

  create_table "ai_policies", force: :cascade do |t|
    t.integer "classroom_id", null: false
    t.json "allowed_modes", default: [], null: false
    t.boolean "review_required", default: false, null: false
    t.integer "daily_limit", default: 20, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "light", default: "yellow", null: false
    t.index ["classroom_id"], name: "index_ai_policies_on_classroom_id", unique: true
  end

  create_table "classrooms", force: :cascade do |t|
    t.string "name", null: false
    t.integer "teacher_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["teacher_id"], name: "index_classrooms_on_teacher_id"
  end

  create_table "data_deletions", force: :cascade do |t|
    t.integer "former_user_id", null: false
    t.string "reason", null: false
    t.json "counts", default: {}, null: false
    t.integer "requested_by_id"
    t.datetime "deleted_at", null: false
    t.index ["requested_by_id"], name: "index_data_deletions_on_requested_by_id"
  end

  create_table "enrollments", force: :cascade do |t|
    t.integer "classroom_id", null: false
    t.integer "student_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classroom_id", "student_id"], name: "index_enrollments_on_classroom_id_and_student_id", unique: true
    t.index ["classroom_id"], name: "index_enrollments_on_classroom_id"
    t.index ["student_id"], name: "index_enrollments_on_student_id"
  end

  create_table "help_sessions", force: :cascade do |t|
    t.integer "student_id", null: false
    t.integer "project_id", null: false
    t.integer "classroom_id"
    t.string "card", null: false
    t.integer "line_number"
    t.string "line_text"
    t.string "source", null: false
    t.string "status", default: "open", null: false
    t.integer "level", default: 0, null: false
    t.integer "resolved_by_id"
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "error_text"
    t.index ["classroom_id"], name: "index_help_sessions_on_classroom_id"
    t.index ["project_id"], name: "index_help_sessions_on_project_id"
    t.index ["resolved_by_id"], name: "index_help_sessions_on_resolved_by_id"
    t.index ["student_id"], name: "index_help_sessions_on_student_id"
  end

  create_table "milestones", force: :cascade do |t|
    t.integer "stage_id", null: false
    t.integer "position", null: false
    t.string "category", null: false
    t.string "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "kid_description"
    t.index ["stage_id"], name: "index_milestones_on_stage_id"
  end

  create_table "parent_consents", force: :cascade do |t|
    t.integer "student_id", null: false
    t.string "parent_name", null: false
    t.string "parent_email", null: false
    t.string "token", null: false
    t.string "status", default: "requested", null: false
    t.boolean "account_consent", default: false, null: false
    t.boolean "ai_consent", default: false, null: false
    t.string "signature_name"
    t.string "notice_version"
    t.datetime "requested_at"
    t.datetime "submitted_at"
    t.string "submitted_ip"
    t.datetime "verified_at"
    t.integer "verified_by_id"
    t.string "verification_method"
    t.datetime "ai_verified_at"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["student_id"], name: "index_parent_consents_on_student_id", unique: true
    t.index ["token"], name: "index_parent_consents_on_token", unique: true
    t.index ["verified_by_id"], name: "index_parent_consents_on_verified_by_id"
  end

  create_table "project_versions", force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "author", null: false
    t.text "ruby_source", null: false
    t.text "blocks_json"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_versions_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.integer "student_id", null: false
    t.integer "classroom_id"
    t.integer "stage_id", null: false
    t.string "title", null: false
    t.text "spec"
    t.string "editor_mode", default: "blocks", null: false
    t.text "blocks_json"
    t.text "ruby_source", default: "", null: false
    t.json "authorship", default: [], null: false
    t.integer "hand_edits_after_ai", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classroom_id"], name: "index_projects_on_classroom_id"
    t.index ["stage_id"], name: "index_projects_on_stage_id"
    t.index ["student_id"], name: "index_projects_on_student_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "skill_checks", force: :cascade do |t|
    t.integer "student_id", null: false
    t.integer "milestone_id", null: false
    t.integer "checked_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["checked_by_id"], name: "index_skill_checks_on_checked_by_id"
    t.index ["milestone_id"], name: "index_skill_checks_on_milestone_id"
    t.index ["student_id", "milestone_id"], name: "index_skill_checks_on_student_id_and_milestone_id", unique: true
    t.index ["student_id"], name: "index_skill_checks_on_student_id"
  end

  create_table "stages", force: :cascade do |t|
    t.integer "position", null: false
    t.string "key", null: false
    t.string "name", null: false
    t.string "grades", null: false
    t.integer "min_grade", null: false
    t.integer "max_grade", null: false
    t.string "tool", null: false
    t.string "editor", default: "blocks", null: false
    t.text "coding_focus", null: false
    t.text "ai_focus", null: false
    t.text "computer_focus", null: false
    t.text "project_summary", null: false
    t.json "ai_modes", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "kid_name"
    t.string "emoji"
    t.string "kid_coding"
    t.string "kid_ai"
    t.string "kid_computer"
    t.string "kid_project"
    t.index ["key"], name: "index_stages_on_key", unique: true
    t.index ["position"], name: "index_stages_on_position", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "username", null: false
    t.string "password_digest", null: false
    t.string "role", default: "student", null: false
    t.integer "grade"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "birth_year"
    t.datetime "last_active_at"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "ai_interactions", "classrooms"
  add_foreign_key "ai_interactions", "help_sessions"
  add_foreign_key "ai_interactions", "projects"
  add_foreign_key "ai_interactions", "users", column: "reviewed_by_id"
  add_foreign_key "ai_interactions", "users", column: "student_id"
  add_foreign_key "ai_policies", "classrooms"
  add_foreign_key "classrooms", "users", column: "teacher_id"
  add_foreign_key "data_deletions", "users", column: "requested_by_id"
  add_foreign_key "enrollments", "classrooms"
  add_foreign_key "enrollments", "users", column: "student_id"
  add_foreign_key "help_sessions", "classrooms"
  add_foreign_key "help_sessions", "projects"
  add_foreign_key "help_sessions", "users", column: "resolved_by_id"
  add_foreign_key "help_sessions", "users", column: "student_id"
  add_foreign_key "milestones", "stages"
  add_foreign_key "parent_consents", "users", column: "student_id"
  add_foreign_key "parent_consents", "users", column: "verified_by_id"
  add_foreign_key "project_versions", "projects"
  add_foreign_key "projects", "classrooms"
  add_foreign_key "projects", "stages"
  add_foreign_key "projects", "users", column: "student_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "skill_checks", "milestones"
  add_foreign_key "skill_checks", "users", column: "checked_by_id"
  add_foreign_key "skill_checks", "users", column: "student_id"
end
