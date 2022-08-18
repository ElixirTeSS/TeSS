module HasSuggestions
  extend ActiveSupport::Concern

  included do
    has_one :edit_suggestion, as: :suggestible, dependent: :destroy

    after_create :enqueue_edit_suggestion_worker, if: :requires_suggestions?
    # after_update :destroy_edit_suggestion
  end

  private

  def requires_suggestions?
    !edit_suggestion && self.class.ontology_term_fields.none? { |field| self.send(field).any? }
  end

  def enqueue_edit_suggestion_worker
    EditSuggestionWorker.perform_in(1.second, [id, self.class.name])
  end

  def destroy_edit_suggestion
    # If it's being updated and has an edit suggestion then, for now, this can be removed so it doesn't
    # suggest the same topics on every edit.
    # TODO: Consider whether this is proper behaviour or whether a user should explicitly delete this
    # TODO: suggestion, somehow.
    edit_suggestion.destroy if edit_suggestion
  end
end
