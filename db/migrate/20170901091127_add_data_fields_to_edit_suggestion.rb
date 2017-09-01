class AddDataFieldsToEditSuggestion < ActiveRecord::Migration
  def change
    add_column :edit_suggestions, :data_fields, :json
  end
end
