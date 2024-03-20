# frozen_string_literal: true

class AddUpdatedAtToSources < ActiveRecord::Migration[6.1]
  def up
    add_column :sources, :updated_at, :datetime
    ActiveRecord::Base.connection.execute('UPDATE sources SET updated_at = created_at')
    change_column_default :sources, :updated_at, nil
  end

  def down
    remove_column :sources, :updated_at, :datetime
  end
end
