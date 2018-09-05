class AddTimezoneToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :timezone, :string
  end
end
