# frozen_string_literal: true

class RemoveDefaultFromTimezone < ActiveRecord::Migration[6.1]
  def up
    change_column_default :events, :timezone, from: 'UTC', to: nil
  end

  def down
    change_column_default :events, :timezone, from: nil, to: 'UTC'
  end
end
