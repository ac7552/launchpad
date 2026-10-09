class AddTiersGradingParentsAndMessages < ActiveRecord::Migration[8.0]
  def change
    # Look-and-words tier (explorer / builder / launch_crew). Blank = default for the student's grade.
    add_column :users, :ui_tier, :string

    # A parent or guardian linked to a student. The parent login is created when they accept the invite.
    create_table :guardianships do |t|
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :parent, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.string :email, null: false
      t.string :token, null: false
      t.datetime :claimed_at
      t.timestamps
    end
    add_index :guardianships, :token, unique: true
    add_index :guardianships, [ :student_id, :email ], unique: true

    # Turned-in work and the teacher's grade.
    create_table :project_reviews do |t|
      t.references :project, null: false, foreign_key: true
      t.references :reviewer, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "submitted"
      t.text :student_note
      t.text :code_snapshot
      t.integer :coding
      t.integer :problem_solving
      t.integer :ownership
      t.text :feedback
      t.datetime :submitted_at, null: false
      t.datetime :returned_at
      t.timestamps
    end

    # One shared conversation per student: the student, their parents, and their teachers.
    create_table :message_threads do |t|
      t.references :student, null: false, foreign_key: { to_table: :users }, index: { unique: true }
      t.datetime :last_message_at
      t.timestamps
    end
    create_table :messages do |t|
      t.references :message_thread, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false
      t.boolean :urgent, null: false, default: false
      t.timestamps
    end
    create_table :thread_reads do |t|
      t.references :message_thread, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :last_read_at, null: false
      t.timestamps
    end
    add_index :thread_reads, [ :message_thread_id, :user_id ], unique: true
  end
end
