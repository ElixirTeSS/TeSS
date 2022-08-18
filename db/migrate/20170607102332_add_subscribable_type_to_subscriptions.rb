class AddSubscribableTypeToSubscriptions < ActiveRecord::Migration[4.2]
  def change
    add_column :subscriptions, :subscribable_type, :string
  end
end
