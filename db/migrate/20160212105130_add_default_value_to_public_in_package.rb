class AddDefaultValueToPublicInPackage < ActiveRecord::Migration
  def change
    change_column_default :packages, :public, true
  end
end
