class AddLastScrapedByToScrapableModels < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :last_scraped_by_id, :bigint
    add_column :materials, :last_scraped_by_id, :bigint
  end
end
