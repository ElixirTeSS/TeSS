class AddDefaultValueToLicenceInMaterials < ActiveRecord::Migration
  def self.up
    change_column_default :materials, :licence, 'notspecified'
  end

  def self.down
    change_column_default :materials, :licence, nil
  end
end
