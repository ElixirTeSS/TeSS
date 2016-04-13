class AddUserToNodes < ActiveRecord::Migration
  def change
    add_reference :nodes, :user, index: true, foreign_key: true
  end
end
