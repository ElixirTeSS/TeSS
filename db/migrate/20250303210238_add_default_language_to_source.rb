class AddDefaultLanguageToSource < ActiveRecord::Migration[7.0]
  def change
    add_column :sources, :default_language, :string
  end
end
