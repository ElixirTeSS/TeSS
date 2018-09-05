class AddKeywordsToPacakges < ActiveRecord::Migration[4.2]
  def change
    add_column :packages, :keywords, :string, array: true, default: []
  end
end
