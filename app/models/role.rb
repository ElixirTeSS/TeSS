class Role < ActiveRecord::Base
  has_many :users

  # Look in config/data/roles.yml to find role definitions

  # Use this with Role.create_roles on a new installation
  # to set the initial roles up if not using seeds.
  def self.create_roles
    roles = YAML.load(File.read(File.join(Rails.root, 'config', 'data', 'roles.yml')))
    roles.each do |name, data|
      r = Role.find_or_create(name: name)
      r.update_attributes(data)
    end
  end

end
