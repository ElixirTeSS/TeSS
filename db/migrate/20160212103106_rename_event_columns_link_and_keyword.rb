class RenameEventColumnsLinkAndKeyword < ActiveRecord::Migration
  def change
    rename_column :events, :link, :url
    rename_column :events, :keyword, :keywords
  end
end
