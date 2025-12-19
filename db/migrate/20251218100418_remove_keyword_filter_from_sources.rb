class RemoveKeywordFilterFromSources < ActiveRecord::Migration[7.2]
  def change
    remove_column :sources, :keyword_filter, :string
  end
end
