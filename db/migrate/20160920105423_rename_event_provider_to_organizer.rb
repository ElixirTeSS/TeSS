class RenameEventProviderToOrganizer < ActiveRecord::Migration
  def change
    rename_column :events, :provider, :organizer
  end
end
