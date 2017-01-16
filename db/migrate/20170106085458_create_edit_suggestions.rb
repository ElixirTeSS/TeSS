class CreateEditSuggestions < ActiveRecord::Migration
  def change
    create_table :edit_suggestions do |t|
      t.text :name, :text
      t.timestamps null: false
    end
  end
end
