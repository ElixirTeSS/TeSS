class CreateEditSuggestions < ActiveRecord::Migration
  def change
    create_table :edit_suggestions do |t|

      t.timestamps null: false
    end
  end
end
