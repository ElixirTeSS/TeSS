class AddContentProviderToMaterials < ActiveRecord::Migration
  def change
    add_reference :materials, :content_provider, index: true, foreign_key: true
  end
end
