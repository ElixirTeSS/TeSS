module SimpleForm
  module Components
    module DisabledForm
      # Name of the component method
      def disabled_form(list, wrapper_options = nil)
        'hidden' if list.include? attribute_name
      end

      # Used when the disabled_form is optional
      def has_disabled_form?
        disabled_form.present?
      end
    end
  end
end

SimpleForm::Inputs::Base.send(:include, SimpleForm::Components::DisabledForm)
