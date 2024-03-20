# frozen_string_literal: true

class ShrinkPackageActivityLogs < ActiveRecord::Migration[4.2]
  def up
    PublicActivity::Activity.transaction do
      PublicActivity::Activity.where(key: 'package.add_material').each do |activity|
        new_parameters = {}
        next unless activity.parameters.key?(:material)

        new_parameters[:material_id] = activity.parameters[:material].try(:id)
        new_parameters[:material_title] = activity.parameters[:material].try(:title)
        activity.update_column(:parameters, new_parameters)
      end

      PublicActivity::Activity.where(key: 'material.add_to_package').each do |activity|
        new_parameters = {}
        next unless activity.parameters.key?(:package)

        new_parameters[:package_id] = activity.parameters[:package].try(:id)
        new_parameters[:package_title] = activity.parameters[:package].try(:title)
        activity.update_column(:parameters, new_parameters)
      end
    end
  end

  def down
    PublicActivity::Activity.transaction do
      PublicActivity::Activity.where(key: 'package.add_material').each do |activity|
        new_parameters = {}
        if activity.parameters.key?(:material_id)
          new_parameters[:material] = Material.find_by_id(activity.parameters[:material_id])
          activity.update_column(:parameters, new_parameters)
        end
      end

      PublicActivity::Activity.where(key: 'material.add_to_package').each do |activity|
        new_parameters = {}
        if activity.parameters.key?(:package_id)
          new_parameters[:package] = Package.find_by_id(activity.parameters[:package_id])
          activity.update_column(:parameters, new_parameters)
        end
      end
    end
  end
end
