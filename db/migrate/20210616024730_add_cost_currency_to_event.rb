class AddCostCurrencyToEvent < ActiveRecord::Migration[5.2]
  def change
    change_column_default :events, :cost_basis, from: '{}', to: nil
    add_column :events, :cost_currency, :string
  end
end
