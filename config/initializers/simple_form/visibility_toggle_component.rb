# frozen_string_literal: true

module SimpleForm
  module Components
    module VisibilityToggle
      # Name of the component method
      def visibility_toggle(_wrapper_options = nil)
        html_classes << 'hidden' if hidden?
        nil
      end

      private

      def hidden?
        visibility_toggle = options[:visibility_toggle] || TeSS::Config&.feature&.dig("#{@builder&.object_name&.to_s&.pluralize}_disabled") || []
        visibility_toggle.include?(attribute_name.to_s)
      end
    end
  end
end

SimpleForm::Inputs::Base.include SimpleForm::Components::VisibilityToggle
