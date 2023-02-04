class FixNilSponsors < ActiveRecord::Migration[4.2]
  # We need to define the Event class locally,
  # so it doesn't use any of the logic defined in the application
  # (which may be out of date with this migration)
  class Event < ActiveRecord::Base; end

  def up
    # the below is postgresql-specific. Is that good enough?
    # Actually I think we can ignore this migration from now on.
    # Event.where(sponsors: nil).update_all("sponsors = '{}'")
  end

  def down
  end
end
