class CreateParentConsents < ActiveRecord::Migration[8.0]
  def change
    # COPPA: verifiable parental consent for students under 13, with a separate consent for
    # sharing project data with the AI provider.
    create_table :parent_consents do |t|
      t.references :student, null: false, foreign_key: { to_table: :users }, index: { unique: true }
      t.string :parent_name, null: false
      t.string :parent_email, null: false
      t.string :token, null: false
      t.string :status, null: false, default: "requested"
      t.boolean :account_consent, null: false, default: false
      t.boolean :ai_consent, null: false, default: false
      t.string :signature_name
      t.string :notice_version
      t.datetime :requested_at
      t.datetime :submitted_at
      t.string :submitted_ip
      t.datetime :verified_at
      t.references :verified_by, foreign_key: { to_table: :users }
      t.string :verification_method
      t.datetime :ai_verified_at
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :parent_consents, :token, unique: true

    # A record that a child's data was deleted, without any of the child's personal information.
    create_table :data_deletions do |t|
      t.integer :former_user_id, null: false
      t.string :reason, null: false
      t.json :counts, null: false, default: {}
      t.references :requested_by, foreign_key: { to_table: :users }
      t.datetime :deleted_at, null: false
    end

    add_column :users, :last_active_at, :datetime
  end
end
