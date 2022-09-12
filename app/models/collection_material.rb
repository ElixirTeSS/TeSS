class CollectionMaterial < ApplicationRecord
  belongs_to :material
  belongs_to :collection

  include PublicActivity::Common

  self.primary_key = 'id'

  after_save :log_activity
  after_create do
    material.solr_index
  end
  after_destroy do
    material.solr_index
  end

  def log_activity
    self.collection.create_activity(:add_material, owner: User.current_user,
                                 parameters: { material_id: self.material_id, material_title: self.material.title })
    self.material.create_activity(:add_to_collection, owner: User.current_user,
                                  parameters: { collection_id: self.collection_id, collection_title: self.collection.title })
  end
end
