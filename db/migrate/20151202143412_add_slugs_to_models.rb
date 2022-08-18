class AddSlugsToModels < ActiveRecord::Migration[4.2]
  def change

    add_column :content_providers, :slug, :string
    add_index :content_providers, :slug, unique: true

    add_column :events, :slug, :string
    add_index :events, :slug, unique: true

    add_column :materials, :slug, :string
    add_index :materials, :slug, unique: true

    add_column :nodes, :slug, :string
    add_index :nodes, :slug, unique: true

    add_column :packages, :slug, :string
    add_index :packages, :slug, unique: true

    add_column :profiles, :slug, :string
    add_index :profiles, :slug, unique: true

    add_column :users, :slug, :string
    add_index :users, :slug, unique: true

    add_column :workflows, :slug, :string
    add_index :workflows, :slug, unique: true
  end
end
