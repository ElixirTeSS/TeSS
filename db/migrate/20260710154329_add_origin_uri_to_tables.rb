class AddOriginUriToTables < ActiveRecord::Migration[8.1]
  def change
    add_column :materials, :origin_uri, :string
    add_column :events, :origin_uri, :string
  end
end
