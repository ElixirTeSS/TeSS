class AddDisabledFeaturesToSpaces < ActiveRecord::Migration[7.2]
  def change
    add_column :spaces, :disabled_features, :string, array: true, default: []
  end
end
