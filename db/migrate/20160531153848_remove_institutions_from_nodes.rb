class RemoveInstitutionsFromNodes < ActiveRecord::Migration
  def change
    remove_column :nodes, :institutions, :array
  end
end
