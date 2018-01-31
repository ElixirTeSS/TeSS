class AddDefaultToEditSuggestionsDataFields < ActiveRecord::Migration
  def change
    change_column_default :edit_suggestions, :data_fields, {}
  end
end
