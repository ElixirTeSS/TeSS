class AddEnabledToSources < ActiveRecord::Migration[5.2]
  def change
    add_column :sources, :enabled, :boolean
  end
end
