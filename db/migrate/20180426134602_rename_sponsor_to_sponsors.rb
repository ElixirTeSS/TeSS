class RenameSponsorToSponsors < ActiveRecord::Migration
  def change
    rename_column :events, :sponsor, :sponsors
  end
end
