class AddKeywordFilterToSources < ActiveRecord::Migration[7.2]
  def change
    add_column :sources, :keyword_filter, :string
  end
end
