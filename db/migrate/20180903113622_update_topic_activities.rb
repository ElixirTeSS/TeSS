unless defined?(PublicActivity::Activity)
  class PublicActivity::Activity < ActiveRecord::Base; end
end

class UpdateTopicActivities < ActiveRecord::Migration[4.2]
  def up
    puts 'Updating old "*_topic" activities'
    ['event', 'material'].each do |type|
      ['add', 'reject'].each do |subaction|
        PublicActivity::Activity.where(key: "#{type}.#{subaction}_topic").each do |activity|
          activity.update_column(:key, "#{type}.#{subaction}_term")
          parameters = activity.parameters
          unless parameters.key?(:field)
            if parameters[:uri].include?('edamontology.org/topic_')
              activity.update_column(:parameters, parameters.merge(field: 'topics'))
            elsif parameters[:uri].include?('edamontology.org/operation_')
              activity.update_column(:parameters, parameters.merge(field: 'operations'))
            end
          end
          print '.'
        end
      end
    end
    puts
  end

  def down
  end
end
