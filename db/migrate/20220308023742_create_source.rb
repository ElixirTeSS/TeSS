class CreateSource < ActiveRecord::Migration[5.2]
  def change
    create_table :sources do |t|
      t.references :content_provider, foreign_key: true
      t.integer :identifier
      t.string :url
      t.string :method
      t.string :resource_type
    end

    create_table :results do |t|
      t.references :source, foreign_key: true
      t.datetime :finished
      t.string :filename
      t.integer :records_read
      t.integer :records_written
      t.integer :log_level
    end
  end
end
