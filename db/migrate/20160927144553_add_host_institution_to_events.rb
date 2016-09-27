class AddHostInstitutionToEvents < ActiveRecord::Migration
  def change
    add_column :events, :host_institutions, :string, array: true, default: []
  end
end
