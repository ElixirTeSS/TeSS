# frozen_string_literal: true

class RemoveKeywordFromMaterials < ActiveRecord::Migration[6.1]
  def up
    return unless ActiveRecord::Base.connection.column_exists?(:materials, :keyword)

    remove_column :materials, :keyword
  end

  def down
    return if ActiveRecord::Base.connection.column_exists?(:materials, :keyword)

    add_column :materials, :keyword, :text
  end
end
