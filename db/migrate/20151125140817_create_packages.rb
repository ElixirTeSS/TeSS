class CreatePackages < ActiveRecord::Migration[4.2]
  def change
    create_table :packages do |t|
      t.string :name
      t.text :description
      t.string :image_url
      t.boolean :public

      t.timestamps null: false
    end
  end
end
