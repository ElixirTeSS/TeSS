class AddTopicRefToMaterial < ActiveRecord::Migration
  def change
    add_reference :materials, :scientific_topic, index: true, foreign_key: true
  end
end
