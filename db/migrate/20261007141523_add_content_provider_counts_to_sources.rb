class AddContentProviderCountsToSources < ActiveRecord::Migration[8.1]
  def change
    add_column :sources, :content_providers_added, :integer, default: 0, null: false
    add_column :sources, :content_providers_rejected, :integer, default: 0, null: false
  end
end
