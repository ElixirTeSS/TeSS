class RenameContentProviderColumnLogoUrl < ActiveRecord::Migration[4.2]
  def change
    rename_column :content_providers, :logo_url, :image_url
  end
end
