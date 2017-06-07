class AddLastCheckedAtToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :last_checked_at, :datetime
  end
end
