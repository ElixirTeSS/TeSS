class AddHideChildNodesToggleToWorkflows < ActiveRecord::Migration
  def change
    add_column :workflows, :hide_child_nodes, :boolean, default: false
  end
end
