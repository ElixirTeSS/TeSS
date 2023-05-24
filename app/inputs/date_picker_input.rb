# frozen_string_literal: true

class DatePickerInput < SimpleForm::Inputs::Base
  def input(wrapper_options)
    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    template.date_picker(@builder, attribute_name, merged_input_options)
  end
end
