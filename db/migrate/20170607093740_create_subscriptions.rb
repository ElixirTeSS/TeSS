class CreateSubscriptions < ActiveRecord::Migration[4.2]
  def change
    create_table :subscriptions do |t|
      t.references :user, index: true, foreign_key: true
      t.datetime :last_sent_at
      t.text :query
      t.json :facets
      t.integer :frequency

      t.timestamps null: false
    end
  end
end
