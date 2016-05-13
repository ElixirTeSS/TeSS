class CreateStaffMembers < ActiveRecord::Migration
  def change
    create_table :staff_members do |t|
      t.string :name
      t.string :role
      t.string :email
      t.text :image_url
      t.references :node, index: true, foreign_key: true
      t.boolean :is_coordinator, default: false

      t.timestamps null: false
    end
  end
end
