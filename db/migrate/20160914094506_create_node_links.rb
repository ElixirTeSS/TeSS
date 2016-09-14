class CreateNodeLinks < ActiveRecord::Migration
  def change
    create_table :node_links do |t|
      t.references :node, index: true, foreign_key: true
      t.references :resource, polymorphic: true, index: true
    end
  end
end
