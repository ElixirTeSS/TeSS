class UpdateOrcidsInProfiles < ActiveRecord::Migration[7.2]
  ORCID_PREFIX = 'https://orcid.org/'.freeze
  def up
    Profile.where('orcid IS NOT NULL').find_each do |profile|
      profile.update_column(:orcid, profile.orcid.gsub(ORCID_PREFIX, ''))
    end
  end

  def down
    Profile.where('orcid IS NOT NULL').find_each do |profile|
      profile.update_column(:orcid, "#{ORCID_PREFIX}#{profile.orcid}") unless profile.orcid.start_with?(ORCID_PREFIX)
    end
  end
end
