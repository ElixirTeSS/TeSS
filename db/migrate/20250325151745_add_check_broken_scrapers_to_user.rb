class AddCheckBrokenScrapersToUser < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :check_broken_scrapers, :boolean, default: false
  end
end
