class AddLastScrapedToMaterials < ActiveRecord::Migration
  def change
    change_table :materials do |t|
      t.date :last_scraped
      t.boolean :scraper_record, :default => false
    end
  end
end
