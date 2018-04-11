class AddLinkMonitors < ActiveRecord::Migration

  def change
    create_table :link_monitors do |t|
      t.string :url
      t.integer :code
      t.datetime :failed_at, null: false
      t.datetime :last_failed_at, null: false
      t.integer :fail_count
      t.references :lcheck, polymorphic: true, index: true
    end

  end

end
