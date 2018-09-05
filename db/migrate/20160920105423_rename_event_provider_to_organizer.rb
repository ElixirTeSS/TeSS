class RenameEventProviderToOrganizer < ActiveRecord::Migration[4.2]
  def change
    rename_column :events, :provider, :organizer
  end
end
