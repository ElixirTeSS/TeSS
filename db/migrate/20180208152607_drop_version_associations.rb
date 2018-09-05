class DropVersionAssociations < ActiveRecord::Migration[4.2]
  def change
    drop_table 'version_associations' do |t|
      t.integer 'version_id'
      t.string 'foreign_key_name', null: false
      t.integer 'foreign_key_id'
    end
  end
end
