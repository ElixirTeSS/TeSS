# frozen_string_literal: true

class UpdateDetailsOfMaterials < ActiveRecord::Migration[5.2]
  def up
    add_column :materials, :contact, :text

    ActiveRecord::Base.connection.execute("UPDATE materials SET long_description = short_description WHERE (long_description = '') IS NOT FALSE")

    remove_column :materials, :short_description
  end

  def down
    remove_column :materials, :contact, :text

    # This is a lossy operation :(

    add_column :materials, :short_description, :string
  end
end
