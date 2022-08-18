class AddUserToContentProviders < ActiveRecord::Migration[4.2]
  def change
    add_reference :content_providers, :user, index: true, foreign_key: true
  end
end
