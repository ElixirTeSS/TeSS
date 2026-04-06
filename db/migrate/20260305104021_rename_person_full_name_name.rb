class RenamePersonFullNameName < ActiveRecord::Migration[7.2]
  def change
    rename_column :people, :full_name, :name
  end
end
