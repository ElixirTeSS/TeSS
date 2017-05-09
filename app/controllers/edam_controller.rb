class EdamController < ApplicationController

  def terms
    list(EDAM::Ontology.instance.all_topics + EDAM::Ontology.instance.all_operations)
  end

  def operations
    list(EDAM::Ontology.instance.all_operations)
  end

  def topics
    list(EDAM::Ontology.instance.all_topics)
  end

  private

  def list(terms)
    @terms = terms

    if params[:filter]
      @terms = @terms.select { |t| t.preferred_label.downcase.start_with?(params[:filter].downcase) }
    end

    render 'index', format: :json
  end

end
