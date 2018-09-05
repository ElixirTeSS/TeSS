class AddUserToPackage < ActiveRecord::Migration[4.2]
  def change
    add_reference :packages, :user, index: true, foreign_key: true
  end
end
