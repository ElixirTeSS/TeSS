class CreateSpaces < ActiveRecord::Migration[7.2]
  def change
    create_table :spaces do |t|
      t.string :title
      t.text :description
      t.string :host
      t.string :theme
      t.attachment :image
      t.references :user, foreign_key: true
      t.timestamps
      t.index ['host'], name: 'index_spaces_on_host', unique: true
    end
  end
end
