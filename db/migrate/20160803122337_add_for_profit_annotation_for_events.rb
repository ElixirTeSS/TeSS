class AddForProfitAnnotationForEvents < ActiveRecord::Migration[4.2]
  def up
    add_column :events, :for_profit, :boolean, :default => false
    add_index :events, :for_profit
  end

  def down
    remove_index :events, :for_profit
    remove_column :events, :for_profit
  end
end
