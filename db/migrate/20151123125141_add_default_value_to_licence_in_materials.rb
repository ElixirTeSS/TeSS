class AddDefaultValueToLicenceInMaterials < ActiveRecord::Migration[4.2]
  def self.up
    change_column_default :materials, :licence, 'notspecified'
  end

  def self.down
    change_column_default :materials, :licence, nil
  end
end
