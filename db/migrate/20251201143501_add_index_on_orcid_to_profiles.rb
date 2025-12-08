class AddIndexOnOrcidToProfiles < ActiveRecord::Migration[7.2]
  def change
    add_index :profiles, :orcid
  end
end
