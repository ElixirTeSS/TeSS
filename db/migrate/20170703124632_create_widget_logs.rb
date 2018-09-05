class CreateWidgetLogs < ActiveRecord::Migration[4.2]
  def change
    create_table :widget_logs do |t|
      t.string :widget_name
      t.string :action
      t.references :resource, polymorphic: true, index: true
      t.text :data
      t.json :params

      t.timestamps null: false
    end
  end
end
