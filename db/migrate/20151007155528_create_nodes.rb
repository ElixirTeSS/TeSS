class CreateNodes < ActiveRecord::Migration[4.2]
  def change
    create_table :nodes do |t|
      t.string :name
      t.string :member_status
      t.string :country_code
      t.string :home_page
      t.string :institutions, array: true
      t.string :trc
      t.string :trc_email
      t.string :trc
      t.string :staff, array: true
      t.string :twitter
      t.string :carousel_images, array: true

      t.timestamps null: false
    end
  end
end
