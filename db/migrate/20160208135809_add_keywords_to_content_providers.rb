class AddKeywordsToContentProviders < ActiveRecord::Migration[4.2]
  def change
    add_column :content_providers, :keywords, :string, array: true, default: []
  end
end
