# frozen_string_literal: true

class ConvertOnlineToInteger < ActiveRecord::Migration[6.1]
  def up
    change_column_default :events, :online, nil
    change_column :events, :online, :integer, using: 'online::integer', default: 0
  end

  def down
    change_column_default :events, :online, nil
    change_column :events, :online, :boolean, using: 'online::boolean', default: false
  end
end
