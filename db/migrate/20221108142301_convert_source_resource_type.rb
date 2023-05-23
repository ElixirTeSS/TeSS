# frozen_string_literal: true

class ConvertSourceResourceType < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.connection.execute("UPDATE sources SET method = 'event_csv' WHERE method = 'csv' AND resource_type = 'event'")
    ActiveRecord::Base.connection.execute("UPDATE sources SET method = 'material_csv' WHERE method = 'csv' AND resource_type = 'material'")
    ActiveRecord::Base.connection.execute("UPDATE sources SET method = 'ical' WHERE method = 'ical' AND resource_type = 'event'")
    ActiveRecord::Base.connection.execute("UPDATE sources SET method = 'zenodo' WHERE method = 'rest' AND resource_type = 'material'")
    ActiveRecord::Base.connection.execute("UPDATE sources SET method = 'tess_event' WHERE method = 'rest' AND resource_type = 'event' AND url LIKE 'https://tess.elixir-europe.org/%'")
    ActiveRecord::Base.connection.execute("UPDATE sources SET method = 'eventbrite' WHERE method = 'rest' AND resource_type = 'event' AND url LIKE 'https://www.eventbriteapi.com/v3/%'")
  end

  def down
    ActiveRecord::Base.connection.execute("UPDATE sources SET method = 'csv', resource_type = 'event' WHERE method = 'event_csv'")
    ActiveRecord::Base.connection.execute("UPDATE sources SET method = 'csv', resource_type = 'material' WHERE method = 'material_csv'")
    ActiveRecord::Base.connection.execute("UPDATE sources SET method = 'ical', resource_type = 'event' WHERE method = 'ical'")
    ActiveRecord::Base.connection.execute("UPDATE sources SET method = 'rest', resource_type = 'material' WHERE method = 'zenodo'")
    ActiveRecord::Base.connection.execute("UPDATE sources SET method = 'rest', resource_type = 'event' WHERE method = 'tess_event'")
    ActiveRecord::Base.connection.execute("UPDATE sources SET method = 'rest', resource_type = 'event' WHERE method = 'eventbrite'")
  end
end
