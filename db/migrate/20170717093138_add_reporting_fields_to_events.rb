class AddReportingFieldsToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :funding, :string
    add_column :events, :attendee_count, :integer
    add_column :events, :applicant_count, :integer
    add_column :events, :trainer_count, :integer
    add_column :events, :feedback, :string
    add_column :events, :notes, :text
  end
end
