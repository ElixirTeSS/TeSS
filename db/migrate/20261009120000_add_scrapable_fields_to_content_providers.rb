class AddScrapableFieldsToContentProviders < ActiveRecord::Migration[8.1]
  def change
    add_column :content_providers, :scraper_record, :boolean, default: false
    add_column :content_providers, :last_scraped, :date
    add_reference :content_providers, :last_scraped_by, foreign_key: { to_table: :sources, on_delete: :nullify }
  end
end
