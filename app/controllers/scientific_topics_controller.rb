class ScientificTopicsController < ApplicationController
  before_action :set_scientific_topic, only: [:show, :edit, :update, :destroy]
  before_action :set_breadcrumbs

  # GET /scientific_topics
  # GET /scientific_topics.json
  def index
    if params[:filter]
      @scientific_topics = ScientificTopic.where('lower(preferred_label) LIKE ?', "#{params[:filter].downcase}%")
    else
      @scientific_topics = ScientificTopic.all
    end
  end

  # GET /scientific_topics/1
  # GET /scientific_topics/1.json
  def show
  end

  # GET /scientific_topics/new
  def new
    authorize ScientificTopic
    @scientific_topic = ScientificTopic.new
  end

  # GET /scientific_topics/1/edit
  def edit
    authorize @scientific_topic
  end

  # POST /scientific_topics
  # POST /scientific_topics.json
  def create
    authorize ScientificTopic
    @scientific_topic = ScientificTopic.new(scientific_topic_params)

    respond_to do |format|
      if @scientific_topic.save
        format.html { redirect_to @scientific_topic, notice: 'Scientific topic was successfully created.' }
        format.json { render :show, status: :created, location: @scientific_topic }
      else
        format.html { render :new }
        format.json { render json: @scientific_topic.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /scientific_topics/1
  # PATCH/PUT /scientific_topics/1.json
  def update
    authorize @scientific_topic
    respond_to do |format|
      if @scientific_topic.update(scientific_topic_params)
        format.html { redirect_to @scientific_topic, notice: 'Scientific topic was successfully updated.' }
        format.json { render :show, status: :ok, location: @scientific_topic }
      else
        format.html { render :edit }
        format.json { render json: @scientific_topic.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /scientific_topics/1
  # DELETE /scientific_topics/1.json
  def destroy
    authorize @scientific_topic
    @scientific_topic.destroy
    respond_to do |format|
      format.html { redirect_to scientific_topics_url, notice: 'Scientific topic was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_scientific_topic
      @scientific_topic = ScientificTopic.friendly.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def scientific_topic_params
      params.require(:scientific_topic).permit(:preferred_label, :synonyms, :definitions, :obsolete, :parents, :created_in, :documentation, :prefix_iri, :consider, :has_alternative_id, :has_broad_synonym, :has_dbxref, :has_definition, :has_exact_synonym, :has_related_synonym, :has_subset, :replaced_by, :saved_by, :subset_property, :obsolete_since)
    end
end
