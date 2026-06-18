class AddIsPrivateToSpaces < ActiveRecord::Migration[7.2]
  def change
    add_column :spaces, :is_private, :boolean
  end
end
