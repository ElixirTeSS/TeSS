class Profile < ActiveRecord::Base
  belongs_to :user

=begin
  extend FriendlyId
  friendly_id [:firstname, :surname], use: :slugged
=end

  if SOLR_ENABLED==true
    searchable do
      text :firstname
      text :surname
      text :website
      text :email
      text :image_url
      time :updated_at
    end
  end

  #validates :email, presence: true

end
