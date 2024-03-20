# frozen_string_literal: true

class ChangeDetailsOnEvent < ActiveRecord::Migration[5.2]
  def up
    rename_column :events, :cost, :cost_value
    change_column :events, :cost_basis, :string, array: false
  end

  def down
    rename_column :events, :cost_value, :cost
    # This is required or the following `change_column` fails with:
    #  "PG::DatatypeMismatch: ERROR:  default for column "cost_basis" cannot be cast automatically to type character varying[]"
    change_column_default :events, :cost_basis, nil
    change_column :events, :cost_basis, :string, array: true, default: [],
                                                 using: "(string_to_array(cost_basis, ','))"
  end
end
