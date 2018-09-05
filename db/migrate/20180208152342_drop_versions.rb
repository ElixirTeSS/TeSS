class DropVersions < ActiveRecord::Migration[4.2]
  def change
    drop_table 'versions' do |t|
      t.string 'item_type', null: false
      t.integer 'item_id', null: false
      t.string 'event', null: false
      t.string 'whodunnit'
      t.text 'object'
      t.datetime 'created_at'
      t.text 'object_changes'
      t.integer 'transaction_id'
    end
  end
end
