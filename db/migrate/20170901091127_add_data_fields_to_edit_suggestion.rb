class AddDataFieldsToEditSuggestion < ActiveRecord::Migration[4.2]
  def change
    add_column :edit_suggestions, :data_fields, :json
  end
end
