class AddContentProviderToMaterials < ActiveRecord::Migration[4.2]
  def change
    add_reference :materials, :content_provider, index: true, foreign_key: true
  end
end
