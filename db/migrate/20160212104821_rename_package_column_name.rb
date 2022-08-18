class RenamePackageColumnName < ActiveRecord::Migration[4.2]
  def change
    rename_column :packages, :name, :title
  end
end
