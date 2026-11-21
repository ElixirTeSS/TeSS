class AddTimezoneInferredToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :timezone_inferred, :boolean, default: false, null: false
    add_column :events, :time_inferred, :boolean, default: false, null: false
  end
end
