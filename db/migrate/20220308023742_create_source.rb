class CreateSource < ActiveRecord::Migration[5.2]
  def change
    create_table :sources do |t|
      t.references :content_provider, foreign_key: true
      t.references :user, foreign_key: true
      t.datetime :created_at
      t.datetime :finished_at
      t.string :url
      t.string :method
      t.string :resource_type
      t.integer :user_id
      t.integer :records_read
      t.integer :records_written
      t.integer :resources_added
      t.integer :resources_updated
      t.integer :resources_rejected
      t.text :log
    end
  end
end
