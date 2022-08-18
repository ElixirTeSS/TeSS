class RenameSponsorToSponsors < ActiveRecord::Migration[4.2]
  def change
    rename_column :events, :sponsor, :sponsors
  end
end
