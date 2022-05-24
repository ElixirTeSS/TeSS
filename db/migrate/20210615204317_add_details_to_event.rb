class AddDetailsToEvent < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :prerequisites, :text
    add_column :events, :tech_requirements, :text
    add_column :events, :cost_basis, :string, array: true, default: []

    remove_index :events, :for_profit
    remove_column :events, :for_profit
  end
end
