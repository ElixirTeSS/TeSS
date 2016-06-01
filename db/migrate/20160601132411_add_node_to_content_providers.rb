class AddNodeToContentProviders < ActiveRecord::Migration
  def change
    add_reference :content_providers, :node, index: true, foreign_key: true
  end
end
