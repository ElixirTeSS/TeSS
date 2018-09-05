class ConvertSponsorToArray < ActiveRecord::Migration[4.2]
  def up
    change_column :events, :sponsor, :string, array: true, default: [], using: "(string_to_array(sponsor, ','))"
  end

  def down
    change_column :events, :sponsor, :string, array: false, default: nil, using: "(array_to_string(sponsor, ','))"
  end
end
