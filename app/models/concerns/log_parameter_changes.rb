module LogParameterChanges

  extend ActiveSupport::Concern

  IGNORED_ATTRIBUTES = ['id', 'updated_at']

  included do
    after_update :log_parameter_changes
  end

  class_methods do
    def is_foreign_key?(attr)
      return false unless attr.end_with?('_id')
      self.reflections.keys.include?(attr.chomp('_id'))
    end
  end

  private

  def log_parameter_changes
    (self.changed - IGNORED_ATTRIBUTES).each do |changed_attribute|
      if self.class.is_foreign_key?(changed_attribute)
        ob = self.send(changed_attribute.chomp('_id'))
        val = ob.respond_to?(:title) ? ob.title : ob.name
      else
        val = self.send(changed_attribute)
      end

      self.create_activity :update_parameter, parameters: { attr: changed_attribute, new_val: val }
    end
  end
end
