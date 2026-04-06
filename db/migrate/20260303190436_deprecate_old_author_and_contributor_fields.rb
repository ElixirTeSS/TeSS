class DeprecateOldAuthorAndContributorFields < ActiveRecord::Migration[7.2]
  def change
    rename_column :materials, :authors, :deprecated_authors
    rename_column :materials, :contributors, :deprecated_contributors
    rename_column :workflows, :authors, :deprecated_authors
    rename_column :workflows, :contributors, :deprecated_contributors
    rename_column :learning_paths, :authors, :deprecated_authors
    rename_column :learning_paths, :contributors, :deprecated_contributors
  end
end
