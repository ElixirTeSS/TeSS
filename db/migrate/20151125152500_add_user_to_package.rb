class AddUserToPackage < ActiveRecord::Migration
  def change
    add_reference :packages, :user, index: true, foreign_key: true
  end
end
