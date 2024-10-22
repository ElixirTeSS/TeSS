class AddReferrerToWidgetLogs < ActiveRecord::Migration[7.0]
  def change
    add_column :widget_logs, :referrer, :string
  end
end
