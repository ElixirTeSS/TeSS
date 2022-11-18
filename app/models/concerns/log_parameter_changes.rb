module LogParameterChanges

  extend ActiveSupport::Concern

  IGNORED_ATTRIBUTES = ['id', 'updated_at', 'workflow_content', 'last_scraped', 'remote_updated_date', 'approval_status']

  included do
    after_update :log_parameter_changes
  end

  class_methods do
    def is_foreign_key?(attr)
      return false unless attr.end_with?('_id')
      self.reflections.keys.include?(attr.chomp('_id'))
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
        ob = self.send(changed_attribute.chomp('_id'))
        if ob
          parameters[:association_name] = ob.respond_to?(:title) ? ob.title : ob.name
        else
          parameters[:association_name] = nil
        end
      end
      parameters[:new_val] = self.send(changed_attribute)
      parameters[:new_val] = parameters[:new_val].to_s if parameters[:new_val].is_a?(Symbol)

      self.create_activity :update_parameter, parameters: parameters
    end
  end

end
