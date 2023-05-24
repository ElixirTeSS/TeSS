# frozen_string_literal: true

class Collaboration < ApplicationRecord
  belongs_to :user
  belongs_to :resource, polymorphic: true

  validates :user, uniqueness: { scope: :resource, message: 'is already a collaborator' }

  # Re-index the associated resource to index the newly added/removed collaborators
  after_save :reindex_resource
  after_destroy :reindex_resource

  private

  def reindex_resource
    Sunspot.index(resource) if TeSS::Config.solr_enabled
  end
end
