class AddSpaceIdToSources < ActiveRecord::Migration[7.2]
  def change
    add_reference :sources, :space, foreign_key: true
  end
end
