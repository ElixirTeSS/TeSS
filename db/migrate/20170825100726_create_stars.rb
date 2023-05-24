# frozen_string_literal: true

class CreateStars < ActiveRecord::Migration[4.2]
  def change
    create_table :stars do |t|
      t.references :user, index: true, foreign_key: true
      t.references :resource, polymorphic: true, index: true

      t.timestamps null: false
    end
  end
end
