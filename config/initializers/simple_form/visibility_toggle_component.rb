module SimpleForm
  module Components
    module VisibilityToggle
      # Name of the component method
      def visibility_toggle(wrapper_options = nil)
        html_classes << 'hidden' if hidden?
        nil
      end

      private

      def hidden?
        # visibility_toggle = options[:visibility_toggle] || []
        # visibility_toggle.include?(attribute_name.to_s) || visibility_toggle.include?(attribute_name.to_sym)
        hidden_beep?(attribute_name, options)
      end

      def hidden_beep?(name, options = {})
        visibility_toggle = options[:visibility_toggle] || []
        visibility_toggle.include?(name.to_s) || visibility_toggle.include?(name.to_sym)
      end
    end
  end
end

SimpleForm::Inputs::Base.send(:include, SimpleForm::Components::VisibilityToggle)