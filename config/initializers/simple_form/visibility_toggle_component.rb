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
        hidden_beep?(attribute_name, options)
      end

      def hidden_beep?(name, options = [])
        visibility_toggle = options[:visibility_toggle] || TeSS::Config.feature["#{@builder.object_name.pluralize}_disabled"] || []
        visibility_toggle.include?(name.to_s)
      end
    end
  end
end

SimpleForm::Inputs::Base.send(:include, SimpleForm::Components::VisibilityToggle)