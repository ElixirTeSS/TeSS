class RemovePackageIdAndProfileIdFromUsersIfPresent < ActiveRecord::Migration
  def up
    if column_exists? :users, :package_id
      remove_column :users, :package_id
    end

    if column_exists? :users, :package_id
      remove_column :users, :profile_id
    end
  end

  def down
    unless column_exists? :users, :package_id
      add_column :users, :package_id, :integer
    end

    unless column_exists? :users, :package_id
      add_column :users, :profile_id, :integer
    end
  end
end
