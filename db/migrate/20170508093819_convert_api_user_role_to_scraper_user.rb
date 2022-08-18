class ConvertApiUserRoleToScraperUser < ActiveRecord::Migration[4.2]
  def up
    role = Role.where(name: 'api_user').first

    if role
      puts 'Changing API user role to scraper user'
      roles = YAML.safe_load(File.read(File.join(Rails.root, 'config', 'data', 'roles.yml')))
      new_role = roles['scraper_user']
      raise "Couldn't find 'scraper_user' in roles.yml" unless new_role
      role.update_columns(name: 'scraper_user', title: new_role['title'])
    end
  end

  def down
    role = Role.where(name: 'scraper_user').first

    if role
      puts 'Reverting scraper user role to API user'
      role.update_columns(name: 'api_user', title: 'API user')
    end
  end
end
