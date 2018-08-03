class ControlledVocabularyValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    if value.respond_to?(:each)
      bad_terms = value.reject { |v| options[:dictionary].lookup(v) }
      if bad_terms.any?
        record.errors[attribute] << (options[:message] || "contained invalid terms: #{bad_terms.join(', ')}")
      end
    else
      unless options[:dictionary].lookup(value)
        record.errors[attribute] << (options[:message] || "must be a controlled vocabulary term")
      end
    end
  end

end
