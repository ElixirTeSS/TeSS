class SetPresenceOnEvents < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.connection.execute("UPDATE events SET presence = 0 WHERE presence IS NULL")
  end

  def down
  end
end
