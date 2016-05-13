class RemoveTrcFieldsFromNodes < ActiveRecord::Migration
  def change
    remove_column :nodes, :trc, :string
    remove_column :nodes, :trc_email, :string
  end
end
