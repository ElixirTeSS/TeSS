class AddContentProviderUpdatesToSources < ActiveRecord::Migration[8.1]
  def change
    add_column :sources, :content_providers_updated, :integer, default: 0, null: false
  end
end
