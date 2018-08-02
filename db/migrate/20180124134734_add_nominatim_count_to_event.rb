class AddNominatimCountToEvent < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :nominatim_count, :integer, default: 0
  end
end
