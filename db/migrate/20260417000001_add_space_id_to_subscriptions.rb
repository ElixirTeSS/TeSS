class AddSpaceIdToSubscriptions < ActiveRecord::Migration[7.2]
  def change
    add_reference :subscriptions, :space, foreign_key: true
  end
end
