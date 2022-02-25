class RenamePackages < ActiveRecord::Migration[6.1]
  def change
    rename_table :packages, :collections
  end
end
