class AddPublicToWorkflows < ActiveRecord::Migration[4.2]
  def change
    add_column :workflows, :public, :boolean, default: true
  end
end
