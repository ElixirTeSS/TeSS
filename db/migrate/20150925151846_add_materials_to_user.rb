class AddMaterialsToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :material_id, :integer
    add_column :materials, :internal_submitter_id, :integer
    add_column :materials, :submitter_id, :integer
    add_column :materials, :author_id, :integer
    add_column :materials, :contributor_id, :integer
  end
end
