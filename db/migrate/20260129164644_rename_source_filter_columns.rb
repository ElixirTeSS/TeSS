class RenameSourceFilterColumns < ActiveRecord::Migration[7.2]
  def change
    rename_column :source_filters, :filter_mode,  :mode
    rename_column :source_filters, :filter_by,    :property
    rename_column :source_filters, :filter_value, :value
  end
end
