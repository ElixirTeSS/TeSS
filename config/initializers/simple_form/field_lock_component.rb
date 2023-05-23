# frozen_string_literal: true

module SimpleForm
  module Components
    module FieldLock
      # Name of the component method
      def field_lock(_wrapper_options = nil)
        @builder.field_lock(attribute_name)
      end

      # Used when the field_lock is optional
      def has_field_lock?
        field_lock.present?
      end
    end
  end
end

SimpleForm::Inputs::Base.include SimpleForm::Components::FieldLock
