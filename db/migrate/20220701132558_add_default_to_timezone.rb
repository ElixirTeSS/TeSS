class AddDefaultToTimezone < ActiveRecord::Migration[6.1]
  def up
    change_column_default :events, :timezone, from: nil, to: 'UTC'
    ActiveRecord::Base.connection.execute("UPDATE events SET timezone = 'UTC' WHERE timezone IS NULL")
  end

  def down
    change_column_default :events, :timezone, from: 'UTC', to: nil
  end
end
