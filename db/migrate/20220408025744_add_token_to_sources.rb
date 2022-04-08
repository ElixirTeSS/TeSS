class AddTokenToSources < ActiveRecord::Migration[5.2]
  def change
    add_column :sources, :token, :string
  end
end
