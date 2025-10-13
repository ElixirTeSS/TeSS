class AddOrcidAuthenticatedToProfiles < ActiveRecord::Migration[7.2]
  def change
    add_column :profiles, :orcid_authenticated, :boolean, default: false
  end
end
