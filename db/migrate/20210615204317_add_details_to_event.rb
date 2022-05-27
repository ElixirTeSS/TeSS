class AddDetailsToEvent < ActiveRecord::Migration[5.2]
  def up
    add_column :events, :prerequisites, :text
    add_column :events, :tech_requirements, :text
    add_column :events, :cost_basis, :string, array: true, default: []

    ActiveRecord::Base.connection.execute("UPDATE events SET cost_basis = '{charge}' WHERE for_profit = true")

    remove_index :events, :for_profit
    remove_column :events, :for_profit
  end

  def down
    add_column :events, :for_profit, :boolean, default: false
    add_index :events, :for_profit

    ActiveRecord::Base.connection.execute("UPDATE events SET for_profit = true WHERE 'charge' = ANY(cost_basis)")

    remove_column :events, :prerequisites, :text
    remove_column :events, :tech_requirements, :text
    remove_column :events, :cost_basis, :string, array: true, default: []
  end
end
