class AddCostAnnotationForEvents < ActiveRecord::Migration[4.2]
  def up
    add_column :events, :cost, :text
    add_index :events, :cost
  end

  def down
    remove_index :events, :cost
    remove_column :events, :cost
  end
end
