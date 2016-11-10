class AddPublicToWorkflows < ActiveRecord::Migration
  def change
    add_column :workflows, :public, :boolean, default: true
  end
end
