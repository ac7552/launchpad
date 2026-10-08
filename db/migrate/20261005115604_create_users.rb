class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :username, null: false
      t.string :password_digest, null: false
      t.string :role, null: false, default: "student"
      t.integer :grade

      t.timestamps
    end
    add_index :users, :username, unique: true
  end
end
