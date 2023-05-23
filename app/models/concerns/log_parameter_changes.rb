# frozen_string_literal: true

module LogParameterChanges
  extend ActiveSupport::Concern

  IGNORED_ATTRIBUTES = ['id', 'updated_at', 'last_scraped', 'remote_updated_date'].freeze

  included do
    after_update :log_parameter_changes
  end

  class_methods do
    def is_foreign_key?(attr)
      return false unless attr.end_with?('_id')

      reflections.keys.include?(attr.chomp('_id'))
    end
  end

  def log_update_activity?
    loggable_changes.any?
  end

  private

  def loggable_changes
    (previous_changes.keys - IGNORED_ATTRIBUTES)
  end

  def log_parameter_changes
    loggable_changes.each do |changed_attribute|
      parameters = { attr: changed_attribute }
      if self.class.is_foreign_key?(changed_attribute)
        ob = send(changed_attribute.chomp('_id'))
        parameters[:association_name] = if ob
                                          ob.respond_to?(:title) ? ob.title : ob.name
                                        end
      end
      parameters[:new_val] = send(changed_attribute)
      parameters[:new_val] = parameters[:new_val].to_s if parameters[:new_val].is_a?(Symbol)

      create_activity :update_parameter, parameters: parameters
    end
  end
end
