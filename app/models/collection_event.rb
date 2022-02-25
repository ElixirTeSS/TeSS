class CollectionEvent < ApplicationRecord
  belongs_to :event
  belongs_to :collection

  include PublicActivity::Common

  self.primary_key = 'id'

  after_save :log_activity

  def log_activity
    self.collection.create_activity(:add_event, owner: User.current_user,
                                 parameters: { event_id: self.event_id, event_title: self.event.title })
    self.event.create_activity(:add_to_collection, owner: User.current_user,
                               parameters: { collection_id: self.collection_id, collection_title: self.collection.title })
  end
end
