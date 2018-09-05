class CreateStaffMembers < ActiveRecord::Migration[4.2]
  def change
    create_table :staff_members do |t|
      t.string :name
      t.string :role
      t.string :email
      t.text :image_url
      t.references :node, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
