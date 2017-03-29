class EdamController < ApplicationController

  def terms
    @terms = EDAM::Ontology.instance.all_topics + EDAM::Ontology.instance.all_operations
    if params[:filter]
      @terms = @terms.select { |t| t.preferred_label.downcase.start_with?(params[:filter].downcase) }
    end

    render 'index', format: :json
  end

  def operations
    @terms = EDAM::Ontology.instance.all_operations
    if params[:filter]
      @terms = @terms.select { |t| t.preferred_label.downcase.start_with?(params[:filter].downcase) }
    end

    render 'index', format: :json
  end

  def topics
    @terms = EDAM::Ontology.instance.all_topics
    if params[:filter]
      @terms = @terms.select { |t| t.preferred_label.downcase.start_with?(params[:filter].downcase) }
    end

    render 'index', format: :json
  end

end
