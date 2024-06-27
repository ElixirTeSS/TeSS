class ControlledVocabularyOrNilValidator < ControlledVocabularyValidator

  # Consider a nil value as also valid
  def validate_each(record, attribute, value)
    return unless value
    super(record, attribute, value)
  end

end

