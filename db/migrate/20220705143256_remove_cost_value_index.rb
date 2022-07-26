class RemoveCostValueIndex < ActiveRecord::Migration[6.1]
  def change
    remove_index :events, :cost_value, if_exists: true
  end
end
