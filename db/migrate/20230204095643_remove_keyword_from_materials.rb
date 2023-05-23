# frozen_string_literal: true

class RemoveKeywordFromMaterials < ActiveRecord::Migration[6.1]
  def up
    remove_column :materials, :keyword if ActiveRecord::Base.connection.column_exists?(:materials, :keyword)
  end

  def down
    add_column :materials, :keyword, :text unless ActiveRecord::Base.connection.column_exists?(:materials, :keyword)
  end
end
