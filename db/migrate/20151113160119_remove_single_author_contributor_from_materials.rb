class RemoveSingleAuthorContributorFromMaterials < ActiveRecord::Migration[4.2]
  def change
    remove_column :materials, :author_id, :integer
    remove_column :materials, :contributor_id, :integer
  end
end
