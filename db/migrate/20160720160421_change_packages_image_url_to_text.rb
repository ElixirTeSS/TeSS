class ChangePackagesImageUrlToText < ActiveRecord::Migration[4.2]
  def change
    change_column :packages, :image_url, :text
  end
end
