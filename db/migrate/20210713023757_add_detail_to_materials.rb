class AddDetailToMaterials < ActiveRecord::Migration[5.2]
  def change
    add_column :materials, :duration, :string
    add_column :materials, :date_created, :date
    add_column :materials, :date_modified, :date
    add_column :materials, :date_published, :date
    add_column :materials, :prerequisites, :text
    add_column :materials, :version, :string
    add_column :materials, :status, :string
    add_column :materials, :syllabus, :text
    add_column :materials, :subsets, :string, default: [], array: true
  end
end
