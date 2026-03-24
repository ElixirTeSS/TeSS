class AddNameIndexToPeople < ActiveRecord::Migration[7.2]
  def change
    add_index :people, :name
  end
end
