class AddFieldsToProfiles < ActiveRecord::Migration[5.2]
  def change
    add_column :profiles, :public, :boolean, default: false
    add_column :profiles, :description, :text
    add_column :profiles, :location, :text
    add_column :profiles, :orcid, :string
    add_column :profiles, :experience, :text
    add_column :profiles, :expertise_academic, :string, array: true, default: []
    add_column :profiles, :expertise_technical, :string, array: true, default: []
    add_column :profiles, :interest, :text, array: true, default: []
    add_column :profiles, :activity, :text, array: true, default: []
    add_column :profiles, :language, :string, array: true, default: []
    add_column :profiles, :social_media, :string, array: true, default: []
  end
end
