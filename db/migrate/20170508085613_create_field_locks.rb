class CreateFieldLocks < ActiveRecord::Migration[4.2]
  def change
    create_table :field_locks do |t|
      t.references :resource, polymorphic: true, index: true
      t.string :field
    end
  end
end
