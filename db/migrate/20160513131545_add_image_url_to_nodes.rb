class AddImageUrlToNodes < ActiveRecord::Migration
  def change
    add_column :nodes, :image_url, :text
  end
end
