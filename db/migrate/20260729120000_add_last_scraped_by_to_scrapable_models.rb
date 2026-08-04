class AddLastScrapedByToScrapableModels < ActiveRecord::Migration[8.1]
  def change
    add_reference :events, :last_scraped_by, foreign_key: { to_table: :sources, on_delete: :nullify }, index: true
    add_reference :materials, :last_scraped_by, foreign_key: { to_table: :sources, on_delete: :nullify }, index: true
  end
end
