class AddUserToNodes < ActiveRecord::Migration[4.2]
  def change
    add_reference :nodes, :user, index: true, foreign_key: true
  end
end
