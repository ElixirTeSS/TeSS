class AddFriendlyIdToScientificTopic < ActiveRecord::Migration
  def change
    add_column   :scientific_topics, :slug,  :string
    add_index    :scientific_topics, :slug, unique: true
  end
end
