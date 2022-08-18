class AddHostInstitutionToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :host_institutions, :string, array: true, default: []
  end
end
