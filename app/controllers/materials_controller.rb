# The controller for actions related to the Materials model
class MaterialsController < ApplicationController
  before_action :feature_enabled?
  before_action :set_material, only: %i[show edit update destroy update_collections clone
                                        add_term reject_term add_data reject_data]
  before_action :set_breadcrumbs
  before_action :set_learning_path_navigation, only: :show

  include SearchableIndex
  include ActionView::Helpers::TextHelper
  include FieldLockEnforcement
  include TopicCuration

  # GET /materials
  # GET /materials?q=queryparam
  # GET /materials.json
  # GET /materials.json?q=queryparam

  def index
    elearning = @facet_params[:resource_type] == 'e-learning' && TeSS::Config.feature['elearning_materials']
    @bioschemas = @materials.flat_map(&:to_bioschemas)
    respond_to do |format|
      format.html { render elearning ? 'elearning_materials/index' : 'index' }
      format.json
      format.json_api { render({ json: @materials }.merge(api_collection_properties)) }
    end
  end

  # GET /materials/1
  # GET /materials/1.json
  def show
    authorize @material
    @bioschemas = @material.to_bioschemas
    respond_to do |format|
      format.html
      format.json
      format.json_api { render json: @material }
    end
  end

  def preview
    @material = User.get_default_user.materials.new(material_params)

    respond_to do |format|
      if @material.valid?
        @bioschemas = @material.to_bioschemas
        format.html { render :show }
      else
        flash[:error] = 'This resource is invalid.'
        format.html { render 'bioschemas/test', status: :unprocessable_entity }
      end
    end
  end

  # GET /materials/new
  def new
    authorize Material
    @material = Material.new
  end

  # GET /materials/1/clone
  def clone
    authorize @material
    @material = @material.duplicate
    render :new
  end

  # GET /materials/1/edit
  def edit
    authorize @material
  end

  # POST /materials/check_title
  # POST /materials/check_title.json
  def check_exists
    @material = Material.check_exists(material_params)

    if @material
      respond_to do |format|
        format.html { redirect_to @material }
        format.json { render :show, location: @material }
      end
    else
      respond_to do |format|
        format.html { render nothing: true, status: 200, content_type: 'text/html' }
        format.json { render json: {}, status: 200, content_type: 'application/json' }
      end
    end
  end

  # POST /materials
  # POST /materials.json
  def create
    authorize Material
    @material = Material.new(material_params)
    @material.user = current_user
    @material.space = current_space

    respond_to do |format|
      if @material.save
        @material.create_activity :create, owner: current_user
        format.html { redirect_to @material, notice: 'Material was successfully created.' }
        format.json { render :show, status: :created, location: @material }
      else
        format.html { render :new }
        format.json { render json: @material.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /materials/1
  # PATCH/PUT /materials/1.json
  def update
    authorize @material
    respond_to do |format|
      if @material.update(material_params)
        @material.create_activity(:update, owner: current_user) if @material.log_update_activity?
        format.html { redirect_to @material, notice: 'Material was successfully updated.' }
        format.json { render :show, status: :ok, location: @material }
      else
        format.html { render :edit }
        format.json { render json: @material.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /materials/1
  # DELETE /materials/1.json
  def destroy
    authorize @material
    @material.create_activity :destroy, owner: current_user
    @material.destroy
    respond_to do |format|
      format.html { redirect_to materials_url, notice: 'Material was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # POST /materials/1/update_collections
  # POST /materials/1/update_collections.json
  def update_collections
    # Go through each selected collection
    # and update its resources to include this material.
    # Go through each other collection that is not selected and remove this material from it.
    collections = params[:material][:collection_ids].select { |p| !p.blank? }
    collections = collections.collect { |collection| Collection.find_by_id(collection) }
    collections_to_remove = @material.collections - collections
    collections.each do |collection|
      collection.update_resources_by_id((collection.materials + [@material.id]).uniq, nil)
    end
    collections_to_remove.each do |collection|
      collection.update_resources_by_id((collection.materials.collect { |x| x.id } - [@material.id]).uniq, nil)
    end
    flash[:notice] = "Material has been included in #{pluralize(collections.count, 'collection')}"
    redirect_to @material
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_material
    @material = Material.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def material_params
    params.require(:material).permit(:id, :title, :url, :contact, :description, :short_description,
                                     :long_description, :doi, :licence,
                                     :last_scraped, :scraper_record, :remote_created_date, :remote_updated_date,
                                     :content_provider_id, :difficulty_level, :version, :status,
                                     :date_created, :date_modified, :date_published, :other_types,
                                     :prerequisites, :syllabus, :visible, :learning_objectives, { subsets: [] },
                                     { contributors: [] }, { authors: [] }, { target_audience: [] },
                                     { collection_ids: [] }, { keywords: [] }, { resource_type: [] },
                                     { scientific_topic_names: [] }, { scientific_topic_uris: [] },
                                     { operation_names: [] }, { operation_uris: [] },
                                     { node_ids: [] }, { node_names: [] }, { fields: [] },
                                     external_resources_attributes: %i[id url title _destroy],
                                     external_resources: %i[url title],
                                     event_ids: [], locked_fields: [])
  end

  def set_learning_path_navigation
    return unless params[:lp]
    topic_link_id, topic_item_id = params[:lp].split(':')
    @learning_path_topic_link = LearningPathTopicLink.find_by_id(topic_link_id)
    @learning_path_topic_item = LearningPathTopicItem.find_by_id(topic_item_id)
  end
end
