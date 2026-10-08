class RemoveAiEnabledFromAiPolicies < ActiveRecord::Migration[8.0]
  def change
    # Replaced by the red/yellow/green light (red = no AI).
    remove_column :ai_policies, :ai_enabled, :boolean, null: false, default: true
  end
end
