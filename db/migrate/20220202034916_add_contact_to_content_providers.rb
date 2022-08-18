class AddContactToContentProviders < ActiveRecord::Migration[5.2]
  def change
    add_column :content_providers, :contact, :string
  end
end
