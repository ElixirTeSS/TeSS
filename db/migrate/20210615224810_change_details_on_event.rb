class ChangeDetailsOnEvent < ActiveRecord::Migration[5.2]
  def change
    remove_index :events, :cost
    remove_column :events, :cost

    add_column :events, :cost_value, :decimal
    change_column :events, :cost_basis, :string, array: false
  end
end
