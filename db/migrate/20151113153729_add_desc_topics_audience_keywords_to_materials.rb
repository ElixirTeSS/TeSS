class AddDescTopicsAudienceKeywordsToMaterials < ActiveRecord::Migration[4.2]
  def change
    add_column :materials, :description, :text
    add_column :materials, :target_audience, :string, array: true, default: []
    add_column :materials, :scientific_topic, :string, array: true, default: []
    add_column :materials, :keywords, :string, array: true, default: []
  end
end
