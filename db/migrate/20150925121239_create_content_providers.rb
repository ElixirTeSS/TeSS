class CreateContentProviders < ActiveRecord::Migration
  def change
    create_table :content_providers do |t|
      t.text :title
      t.text :url
      t.text :logo_url
      t.text :description

      t.timestamps null: false
    end
  end
end
