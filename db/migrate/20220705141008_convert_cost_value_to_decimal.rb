# frozen_string_literal: true

class ConvertCostValueToDecimal < ActiveRecord::Migration[6.1]
  def up
    return if Event.type_for_attribute('cost_value').type == :decimal

    change_column :events, :cost_value, :decimal, using:
      "CASE WHEN (cost_value <> '') IS NOT TRUE THEN NULL ELSE CAST(cost_value AS DECIMAL) END"
  end

  def down
    change_column :events, :cost_value, :text
  end
end
