class Ban < ApplicationRecord
  belongs_to :user, inverse_of: :ban
  belongs_to :banner, class_name: 'User'
  after_create :reindex_user
  after_destroy :reindex_user

  private

  def reindex_user
    Sunspot.index(user.reload.created_resources.to_a) if TeSS::Config.solr_enabled
  end
end
