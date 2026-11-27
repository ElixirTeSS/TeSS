class AddRorToContentProviders < ActiveRecord::Migration[8.1]
  def change
    add_column :content_providers, :ror, :string
    add_index :content_providers, :ror, unique: true
  end
end
