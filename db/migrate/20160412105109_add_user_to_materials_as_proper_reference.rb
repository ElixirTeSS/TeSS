class AddUserToMaterialsAsProperReference < ActiveRecord::Migration[4.2]
  def change
    # Remove the old user_id column
    remove_column :materials, :user_id, :integer
    # Create new 'proper' association (this will recreate user_id column (also foreign key as above),
    # but would also create methods such as material.user, etc.)
    add_reference :materials, :user, index: true, foreign_key: true
  end
end
