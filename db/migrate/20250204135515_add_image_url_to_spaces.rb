class AddImageUrlToSpaces < ActiveRecord::Migration[7.2]
  def change
    add_column :spaces, :image_url, :text
  end
end
