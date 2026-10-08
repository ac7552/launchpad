class CreateLaunchpadCore < ActiveRecord::Migration[8.0]
  def change
    # Curriculum: one stage per grade band, each with milestones students must pass to move up.
    create_table :stages do |t|
      t.integer :position, null: false
      t.string :key, null: false
      t.string :name, null: false
      t.string :grades, null: false
      t.integer :min_grade, null: false
      t.integer :max_grade, null: false
      t.string :tool, null: false
      t.string :editor, null: false, default: "blocks"
      t.text :coding_focus, null: false
      t.text :ai_focus, null: false
      t.text :computer_focus, null: false
      t.text :project_summary, null: false
      t.json :ai_modes, null: false, default: []
      t.timestamps
    end
    add_index :stages, :key, unique: true
    add_index :stages, :position, unique: true

    create_table :milestones do |t|
      t.references :stage, null: false, foreign_key: true
      t.integer :position, null: false
      t.string :category, null: false
      t.string :description, null: false
      t.timestamps
    end

    create_table :skill_checks do |t|
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :milestone, null: false, foreign_key: true
      t.references :checked_by, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :skill_checks, [ :student_id, :milestone_id ], unique: true

    create_table :classrooms do |t|
      t.string :name, null: false
      t.references :teacher, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

    create_table :enrollments do |t|
      t.references :classroom, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :enrollments, [ :classroom_id, :student_id ], unique: true

    # Teacher-controlled AI rules for a class. Effective modes = these ∩ the student's stage modes.
    create_table :ai_policies do |t|
      t.references :classroom, null: false, foreign_key: true, index: { unique: true }
      t.boolean :ai_enabled, null: false, default: true
      t.json :allowed_modes, null: false, default: []
      t.boolean :review_required, null: false, default: false
      t.integer :daily_limit, null: false, default: 20
      t.timestamps
    end

    create_table :projects do |t|
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :classroom, foreign_key: true
      t.references :stage, null: false, foreign_key: true
      t.string :title, null: false
      t.text :spec
      t.string :editor_mode, null: false, default: "blocks"
      t.text :blocks_json
      t.text :ruby_source, null: false, default: ""
      t.json :authorship, null: false, default: []
      t.integer :hand_edits_after_ai, null: false, default: 0
      t.timestamps
    end

    create_table :project_versions do |t|
      t.references :project, null: false, foreign_key: true
      t.string :author, null: false
      t.text :ruby_source, null: false
      t.text :blocks_json
      t.timestamps
    end

    create_table :ai_interactions do |t|
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :project, null: false, foreign_key: true
      t.references :classroom, foreign_key: true
      t.string :mode, null: false
      t.text :prompt, null: false
      t.text :code_snapshot
      t.string :status, null: false, default: "pending"
      t.text :response_text
      t.text :proposed_code
      t.string :proposal_state
      t.string :flag_reason
      t.string :flag_severity
      t.string :model
      t.integer :input_tokens
      t.integer :output_tokens
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.datetime :reviewed_at
      t.timestamps
    end
    add_index :ai_interactions, [ :student_id, :created_at ]
    add_index :ai_interactions, :status
  end
end
