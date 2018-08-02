class AddDefaultValueToPublicInPackage < ActiveRecord::Migration[4.2]
  def change
    change_column_default :packages, :public, true
  end
end
