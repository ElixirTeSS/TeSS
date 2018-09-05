class AddHideChildNodesToggleToWorkflows < ActiveRecord::Migration[4.2]
  def change
    add_column :workflows, :hide_child_nodes, :boolean, default: false
  end
end
