class RenameEventColumnsLinkAndKeyword < ActiveRecord::Migration[4.2]
  def change
    rename_column :events, :link, :url
    rename_column :events, :keyword, :keywords
  end
end
