class CollectionItem < ApplicationRecord
  include PublicActivity::Model
  include LogParameterChanges

  belongs_to :resource, polymorphic: true
  belongs_to :collection, touch: true
  validates :resource_id, uniqueness: { scope: %i[resource_type collection_id], message: 'already included in collection' }

  before_create :set_order
  after_save :log_activity
  after_create :solr_index
  after_destroy :solr_index

  def log_activity
    self.collection.create_activity(:add_item, owner: User.current_user,
                                    parameters: { resource_id: self.resource_id,
                                                  resource_type: self.resource_type,
                                                  resource_title: self.resource.title })
    self.resource.create_activity(:add_to_collection, owner: User.current_user,
                                  parameters: { collection_id: self.collection_id,
                                                collection_title: self.collection.title })
  end

  private

  def set_order
    self.order ||= (collection.items.maximum(:order) || 0) + 1
  end

  def solr_index
    item.solr_index if TeSS::Config.solr_enabled
  end
end
