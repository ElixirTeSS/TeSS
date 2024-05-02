class Community
  include ActiveModel::Model

  attr_accessor :name, :description, :flag, :filters

  def self.find(id)
    if TeSS::Config.communities.key?(id)
      self.new(TeSS::Config.communities[id])
    end
  end
end