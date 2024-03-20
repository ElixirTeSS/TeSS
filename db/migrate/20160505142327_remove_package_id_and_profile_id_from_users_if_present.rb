# frozen_string_literal: true

class RemovePackageIdAndProfileIdFromUsersIfPresent < ActiveRecord::Migration[4.2]
  def up
    remove_column :users, :package_id if column_exists? :users, :package_id

    return unless column_exists? :users, :profile_id

    remove_column :users, :profile_id
  end

  def down
    add_column :users, :package_id, :integer unless column_exists? :users, :package_id

    return if column_exists? :users, :profile_id

    add_column :users, :profile_id, :integer
  end
end
