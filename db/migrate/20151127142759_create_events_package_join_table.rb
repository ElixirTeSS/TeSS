class CreateEventsPackageJoinTable < ActiveRecord::Migration[4.2]
  def change
    create_table :package_events, id: false do |t|
          t.integer :event_id, index: true
          t.integer :package_id, index: true
          t.timestamps null: false
    end
  end
end
