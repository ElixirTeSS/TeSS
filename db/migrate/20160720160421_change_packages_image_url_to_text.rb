class ChangePackagesImageUrlToText < ActiveRecord::Migration
  def change
    change_column :packages, :image_url, :text
  end
end
