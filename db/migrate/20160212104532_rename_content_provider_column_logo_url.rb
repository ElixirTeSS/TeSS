class RenameContentProviderColumnLogoUrl < ActiveRecord::Migration
  def change
    rename_column :content_providers, :logo_url, :image_url
  end
end
