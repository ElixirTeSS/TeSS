class AddDefaultToEditSuggestionsDataFields < ActiveRecord::Migration[4.2]
  def change
    change_column_default :edit_suggestions, :data_fields, {}
  end
end
