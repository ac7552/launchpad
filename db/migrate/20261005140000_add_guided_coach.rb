class AddGuidedCoach < ActiveRecord::Migration[8.0]
  def change
    # Age, not grade, decides who may type to the AI (13+ only).
    add_column :users, :birth_year, :integer

    # NJSBA-style traffic light: red = no AI (hint bank only), yellow = guided coach, green = guided + typed questions for 13+.
    add_column :ai_policies, :light, :string, null: false, default: "yellow"

    # A guided help session starts from a question card and climbs a hint ladder one step at a time.
    create_table :help_sessions do |t|
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :project, null: false, foreign_key: true
      t.references :classroom, foreign_key: true
      t.string :card, null: false
      t.integer :line_number
      t.string :line_text
      t.string :source, null: false
      t.string :status, null: false, default: "open"
      t.integer :level, null: false, default: 0
      t.references :resolved_by, foreign_key: { to_table: :users }
      t.datetime :resolved_at
      t.timestamps
    end

    # Each hint step is logged like any other AI interaction so review, limits, and the audit trail all apply.
    add_reference :ai_interactions, :help_session, foreign_key: true
    add_column :ai_interactions, :level, :integer
    add_column :ai_interactions, :step_kind, :string
    add_column :ai_interactions, :choices, :json
    add_column :ai_interactions, :line_ref, :integer
    add_column :ai_interactions, :kid_choice, :string
    add_column :ai_interactions, :delivered_at, :datetime
  end
end
