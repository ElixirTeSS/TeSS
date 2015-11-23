class Event < ActiveRecord::Base
  include PublicActivity::Common
  has_paper_trail

  searchable do
    text :title
    text :link
    string :city
    string :field
    string :provider
    string :sponsor
    string :venue
    string :city
    string :country
  end

  validates :title, :link, presence: true


  #Make sure there's link and title

  #Generated Event:
  # external_id:string
  # title:string
  # subtitle:string
  # link:string
  # provider:string
  # field:text
  # description:text
  # category:text
  # start:datetime
  # end:datetime
  # sponsor:string
  # venue:text
  # city:string
  # county:string
  # country:string
  # postcode:string
  # latitude:double
  # longitude:double


  def facet_fields
    %w( city field provider sponsor venue city country )
  end
end
