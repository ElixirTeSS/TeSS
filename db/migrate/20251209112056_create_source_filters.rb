class CreateSourceFilters < ActiveRecord::Migration[7.2]
  def change
    create_table :source_filters do |t|
      t.references :source, null: false, foreign_key: true
      t.string :filter_mode
      t.string :filter_by
      t.string :filter_value

      t.timestamps
    end
  end
end
