class Community
  include ActiveModel::Model

  attr_accessor :name, :description, :flag, :filters, :country_code

  def self.find(id)
    if TeSS::Config.communities.key?(id)
      self.new(TeSS::Config.communities[id])
    end
  end

  def self.for_country(iso_code)
    id = TeSS::Config.communities.find do |_, data|
      data.key?('country_code') && data['country_code'] == iso_code
    end&.first

    find(id) if id
  end
end