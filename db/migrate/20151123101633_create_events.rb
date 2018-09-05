class CreateEvents < ActiveRecord::Migration[4.2]
  def change
    create_table :events do |t|
      t.string :external_id
      t.string :title
      t.string :subtitle
      t.string :link
      t.string :provider
      t.text :field
      t.text :description
      t.text :category
      t.datetime :start
      t.datetime :end
      t.string :sponsor
      t.text :venue
      t.string :city
      t.string :county
      t.string :country
      t.string :postcode
      t.decimal :latitude, {:precision=>10, :scale=>6}
      t.decimal :longitude, {:precision=>10, :scale=>6}

      t.timestamps null: false
    end
  end
end
