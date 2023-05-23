# frozen_string_literal: true

class CollectionItem < ApplicationRecord
  include PublicActivity::Model
  include LogParameterChanges

  belongs_to :resource, polymorphic: true
  belongs_to :collection, touch: true
  validates :resource_id,
            uniqueness: { scope: %i[resource_type collection_id], message: 'already included in collection' }

  before_create :set_order
  after_save :log_activity
  after_commit :reindex_resource, on: [:create, :destroy]

  def log_activity
    collection.create_activity(:add_item, owner: User.current_user,
                                          parameters: { resource_id: resource_id,
                                                        resource_type: resource_type,
                                                        resource_title: resource.title })
    resource.create_activity(:add_to_collection, owner: User.current_user,
                                                 parameters: { collection_id: collection_id,
                                                               collection_title: collection.title })
  end

  def reindex_resource
    # we should consider doing this in a background job if it turns out to be slow
    # when curating large collections
    resource.solr_index if TeSS::Config.solr_enabled
  end

  private

  def set_order
    self.order ||= (collection.items.maximum(:order) || 0) + 1
  end
end
