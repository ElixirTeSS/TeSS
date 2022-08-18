class CreateProfiles < ActiveRecord::Migration[4.2]
  def change
    create_table :profiles do |t|
      t.text :firstname
      t.text :surname
      t.text :image_url
      t.text :email
      t.text :website

      t.timestamps null: false
    end
  end
end
