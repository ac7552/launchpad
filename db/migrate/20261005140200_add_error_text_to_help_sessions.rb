class AddErrorTextToHelpSessions < ActiveRecord::Migration[8.0]
  def change
    # The error message from the stage console, for the "I got an error" card.
    add_column :help_sessions, :error_text, :string
  end
end
