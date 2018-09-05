class CreateMaterials < ActiveRecord::Migration[4.2]
  def change
    create_table :materials do |t|
      t.text :title
      t.string :url
      t.string :short_description
      t.string :doi
      t.date :remote_updated_date
      t.date :remote_created_date
      t.date :local_updated_date
      t.date :remote_updated_date

      t.timestamps null: false
    end
  end
end
