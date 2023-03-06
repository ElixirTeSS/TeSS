class CreateAutocompleteSuggestions < ActiveRecord::Migration[6.1]
  def change
    create_table :autocomplete_suggestions do |t|
      t.string :field
      t.string :value
    end

    add_index :autocomplete_suggestions, [:field, :value], unique: true
  end
end
