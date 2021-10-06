class CreateContentProvidersUsersJoinTable < ActiveRecord::Migration[5.2]
  def change
    create_table :editors, id: false do |t|
      t.belongs_to :content_provider, index: true
      t.belongs_to :user, index: true
    end
  end
end
