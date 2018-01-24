class AddNominatimCountToEvent < ActiveRecord::Migration
  def change
    add_column :events, :nominatim_count, :integer, default: 0
  end
end
