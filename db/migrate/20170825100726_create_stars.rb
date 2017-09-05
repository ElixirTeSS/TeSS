class CreateStars < ActiveRecord::Migration
  def change
    create_table :stars do |t|
      t.references :user, index: true, foreign_key: true
      t.references :resource, polymorphic: true, index: true

      t.timestamps null: false
    end
  end
end
