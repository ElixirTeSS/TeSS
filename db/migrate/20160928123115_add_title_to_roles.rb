class AddTitleToRoles < ActiveRecord::Migration[4.2]
  def up
    add_column :roles, :title, :string

    # Update existing roles with titles
    Role.transaction do
      roles = YAML.safe_load(File.read(File.join(Rails.root, 'config', 'data', 'roles.yml')))
      roles.each do |name, data|
        r = Role.find_or_create_by!(name: name)
        r.update_attributes(data)
      end
    end
  end

  def down
    remove_column :roles, :title
  end
end
