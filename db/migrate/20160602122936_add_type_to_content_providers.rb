class AddTypeToContentProviders < ActiveRecord::Migration
  def change
    add_column :content_providers, :content_provider_type, :string, :default => 'Organisation'
    ContentProvider.update_all(content_provider_type: 'Organisation')
  end
end
