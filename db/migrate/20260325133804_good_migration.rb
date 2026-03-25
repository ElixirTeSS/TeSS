class GoodMigration < ActiveRecord::Migration[7.2]
  def change
    add_column :materials, :a_good_field, :string
  end
end
