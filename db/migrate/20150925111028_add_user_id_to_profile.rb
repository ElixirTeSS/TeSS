class AddUserIdToProfile < ActiveRecord::Migration[4.2]
  def change
    add_column :profiles, :user_id, :integer
  end
end
