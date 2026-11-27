class AddRorToContentProviders < ActiveRecord::Migration[8.1]
  def change
    add_column :content_providers, :ror, :string
  end
end
