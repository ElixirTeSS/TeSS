class CreateMaterialsPackageJoinTable < ActiveRecord::Migration
  def change
     create_table :package_materials, id: false do |t|
       t.integer :material_id, index: true
       t.integer :package_id, index: true
       t.timestamps null: false
     end
  end
end
