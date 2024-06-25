class AddLanguageToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :language, :string
  end
end
