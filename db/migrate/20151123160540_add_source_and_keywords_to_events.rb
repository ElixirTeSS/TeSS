class AddSourceAndKeywordsToEvents < ActiveRecord::Migration
  def change
    add_column :events, :keyword, :text
    add_column :events, :source, :text, :default => 'tess'
  end
end
