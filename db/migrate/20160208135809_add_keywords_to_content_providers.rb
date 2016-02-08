class AddKeywordsToContentProviders < ActiveRecord::Migration
  def change
    add_column :content_providers, :keywords, :string, array: true, default: []
  end
end
