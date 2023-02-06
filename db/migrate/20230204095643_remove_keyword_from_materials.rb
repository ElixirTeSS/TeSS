class RemoveKeywordFromMaterials < ActiveRecord::Migration[6.1]
  def up
    if ActiveRecord::Base.connection.column_exists?(:materials, :keyword)
      remove_column :materials, :keyword
    end
  end

  def down
    unless ActiveRecord::Base.connection.column_exists?(:materials, :keyword)
      add_column :materials, :keyword, :text
    end
  end
end
