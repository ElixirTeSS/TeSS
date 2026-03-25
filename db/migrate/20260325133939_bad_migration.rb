class BadMigration < ActiveRecord::Migration[7.2]
  def change
    raise ':('
  end
end
