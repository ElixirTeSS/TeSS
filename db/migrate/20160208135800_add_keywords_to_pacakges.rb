class AddKeywordsToPacakges < ActiveRecord::Migration
  def change
    add_column :packages, :keywords, :string, array: true, default: []
  end
end
