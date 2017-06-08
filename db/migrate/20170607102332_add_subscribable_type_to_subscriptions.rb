class AddSubscribableTypeToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :subscribable_type, :string
  end
end
