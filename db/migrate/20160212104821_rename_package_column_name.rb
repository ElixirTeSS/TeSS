class RenamePackageColumnName < ActiveRecord::Migration
  def change
    rename_column :packages, :name, :title
  end
end
