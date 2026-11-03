class AddIsPrivateToSpaces < ActiveRecord::Migration[7.2]
  def change
    add_column :spaces, :is_private, :boolean, default: false, null: false
  end
end
