class AddSpaceIdToProfiles < ActiveRecord::Migration[7.2]
  def change
    add_reference :profiles, :space, foreign_key: true
  end
end
