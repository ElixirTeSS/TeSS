class AddTimezoneInferredToEvents < ActiveRecord::Migration[7.2]
  def change
    add_column :events, :timezone_inferred, :boolean, default: false, null: false
  end
end
