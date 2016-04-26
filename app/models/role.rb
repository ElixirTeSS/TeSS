class Role < ActiveRecord::Base
  has_many :users

  def self.roles
    return %w{registered_user admin node_curator curator api_user default_user}
  end

  # Use this with Role.create_roles on a new installation
  # to set the initial roles up if not using seeds.
  def self.create_roles
    self.roles.each do |name|
      r = Role.find_by_name(name)
      if r == nil
        r = Role.new(:name => name)
        r.save!
      end
    end
  end

end
