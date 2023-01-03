class ConvertCollectionItems < ActiveRecord::Migration[6.1]
  class CollectionEvent < ActiveRecord::Base; end
  class CollectionMaterial < ActiveRecord::Base; end
  class CollectionItem < ActiveRecord::Base; end

  def up
    CollectionEvent.all.each do |i|
      CollectionItem.where(collection_id: i.collection_id,
                           resource_type: 'Event',
                           resource_id: i.event_id).first_or_create!(updated_at: i.updated_at,
                                                                     created_at: i.created_at)
    end

    CollectionMaterial.all.each do |i|
      CollectionItem.where(collection_id: i.collection_id,
                           resource_type: 'Material',
                           resource_id: i.material_id).first_or_create!(updated_at: i.updated_at,
                                                                        created_at: i.created_at)
    end
  end

  def down
    CollectionItem.where(resource_type: 'Event').find_each do |i|
      CollectionEvent.where(collection_id: i.collection_id,
                            event_id: i.resource_id).first_or_create!(updated_at: i.updated_at,
                                                                      created_at: i.created_at)
    end
    CollectionItem.where(resource_type: 'Material').find_each do |i|
      CollectionMaterial.where(collection_id: i.collection_id,
                               material_id: i.resource_id).first_or_create!(updated_at: i.updated_at,
                                                                            created_at: i.created_at)
    end
  end
end
