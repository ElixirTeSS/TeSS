class RemoveTrcFieldsFromNodes < ActiveRecord::Migration[4.2]
  def change
    remove_column :nodes, :trc, :string
    remove_column :nodes, :trc_email, :string
  end
end
