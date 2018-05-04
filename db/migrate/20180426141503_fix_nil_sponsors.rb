class FixNilSponsors < ActiveRecord::Migration
  def up
    Event.where(sponsors: nil).update_all(sponsors: [])
  end

  def down
  end
end
