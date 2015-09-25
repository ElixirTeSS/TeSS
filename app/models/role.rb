class Role < ActiveRecord::Base
  has_many :users

  def self.roles
    return %w{registered_user admin node_curator curator harvester}
  end

end
