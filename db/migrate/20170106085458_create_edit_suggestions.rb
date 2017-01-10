class CreateEditSuggestions < ActiveRecord::Migration
  def change
    create_table :edit_suggestions do |t|
      add_column :edit_suggestions, :name, :text
      t.timestamps null: false
    end
  end
end
