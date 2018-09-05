class FixNilSponsors < ActiveRecord::Migration[4.2]
  def up
    Event.where(sponsors: nil).update_all(sponsors: [])
  end

  def down
  end
end
