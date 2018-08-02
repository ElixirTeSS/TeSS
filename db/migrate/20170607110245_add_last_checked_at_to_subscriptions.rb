class AddLastCheckedAtToSubscriptions < ActiveRecord::Migration[4.2]
  def change
    add_column :subscriptions, :last_checked_at, :datetime
  end
end
