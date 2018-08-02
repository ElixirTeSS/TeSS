class AddSourceAndKeywordsToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :keyword, :text
    add_column :events, :source, :text, :default => 'tess'
  end
end
