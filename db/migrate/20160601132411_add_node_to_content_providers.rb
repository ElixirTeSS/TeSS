# frozen_string_literal: true

class AddNodeToContentProviders < ActiveRecord::Migration[4.2]
  def change
    add_reference :content_providers, :node, index: true, foreign_key: true
  end
end
