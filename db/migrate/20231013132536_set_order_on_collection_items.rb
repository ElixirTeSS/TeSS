class SetOrderOnCollectionItems < ActiveRecord::Migration[7.0]
  class Collection < ApplicationRecord
    has_many :items, -> { order(:order) }, class_name: 'CollectionItem'
  end

  class CollectionItem < ApplicationRecord
    belongs_to :collection
  end

  def up
    Collection.find_each do |collection|
      indexes = Hash.new(0)
      collection.items.sort_by(&:order).each do |item|
        item.update_column(:order, indexes[item.resource_type] += 1)
      end
    end
  end

  def down
  end
end
