class CreateSpaceRoles < ActiveRecord::Migration[7.2]
  def change
    create_table :space_roles do |t|
      t.string :key
      t.references :user, foreign_key: true, index: true
      t.references :space, foreign_key: true, index: true
      t.timestamps
    end
  end
end
