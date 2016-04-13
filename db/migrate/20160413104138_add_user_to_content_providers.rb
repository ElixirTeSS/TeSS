class AddUserToContentProviders < ActiveRecord::Migration
  def change
    add_reference :content_providers, :user, index: true, foreign_key: true
  end
end
