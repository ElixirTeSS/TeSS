class AddTypeToProfiles < ActiveRecord::Migration[5.2]
  def change
    add_column :profiles, :type, :string, default: 'Profile'
  end
end
