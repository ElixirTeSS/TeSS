class RemoveInstitutionsFromNodes < ActiveRecord::Migration[4.2]
  def change
    remove_column :nodes, :institutions, :array
  end
end
