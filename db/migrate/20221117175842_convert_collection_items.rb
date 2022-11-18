class ConvertCollectionItems < ActiveRecord::Migration[6.1]
  def up
    conn = ActiveRecord::Base.connection

    conn.select_all('SELECT * FROM collection_events').each do |ce|
      values = [ce['collection_id'],
                conn.quote('Event'),
                ce['event_id'],
                conn.quote(ce['created_at']),
                conn.quote(ce['updated_at'])]
      conn.execute("INSERT INTO collection_items (collection_id, resource_type, resource_id, created_at, updated_at) VALUES (#{values.join(', ')})")
    end

    conn.select_all('SELECT * FROM collection_materials').each do |cm|
      values = [cm['collection_id'],
                conn.quote('Material'),
                cm['material_id'],
                conn.quote(cm['created_at']),
                conn.quote(cm['updated_at'])]
      conn.execute("INSERT INTO collection_items (collection_id, resource_type, resource_id, created_at, updated_at) VALUES (#{values.join(', ')})")
    end
  end

  def down
    conn = ActiveRecord::Base.connection

    conn.select_all('SELECT * FROM collection_items').each do |ci|
      values = [ci['resource_id'],
                ci['collection_id'],
                conn.quote(ci['created_at']),
                conn.quote(ci['updated_at'])]
      if ci['resource_type'] == 'Event'
        conn.execute("INSERT INTO collection_events (event_id, collection_id, created_at, updated_at) VALUES (#{values.join(', ')})")
      elsif ci['resource_type'] == 'Material'
        conn.execute("INSERT INTO collection_materials (material_id, collection_id, created_at, updated_at) VALUES (#{values.join(', ')})")
      else
        # Cannot convert
      end
    end
  end
end
