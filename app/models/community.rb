class Community
  include ActiveModel::Model

  attr_accessor :id, :name, :description, :flag, :filters, :country_code

  def self.find(id)
    return nil if id.nil?
    if TeSS::Config.communities.key?(id)
      self.new(TeSS::Config.communities[id].merge(id: id))
    end
  end

  def self.for_country(country_data)
    return nil if country_data.nil?
    id = TeSS::Config.communities.find do |_, data|
      data.key?('country_code') && data['country_code'] == country_data['iso_code']
    end&.first

    find(id) if id
  end
end