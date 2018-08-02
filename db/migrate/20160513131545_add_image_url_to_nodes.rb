class AddImageUrlToNodes < ActiveRecord::Migration[4.2]
  def change
    add_column :nodes, :image_url, :text
  end
end
