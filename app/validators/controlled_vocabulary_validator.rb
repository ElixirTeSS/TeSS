# frozen_string_literal: true

class ControlledVocabularyValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.respond_to?(:each)
      bad_terms = value.reject { |v| lookup(options[:dictionary], v) }
      record.errors.add(attribute, (options[:message] || "contained invalid terms: #{bad_terms.join(', ')}")) if bad_terms.any?
    else
      record.errors.add(attribute, (options[:message] || 'must be a controlled vocabulary term')) unless lookup(options[:dictionary], value)
    end
  end

  private

  def lookup(dictionary, value)
    dictionary.constantize.instance.lookup(value)
  end
end
