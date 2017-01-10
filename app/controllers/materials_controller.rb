class MaterialsController < ApplicationController
  before_action :set_material, only: [:show, :edit, :update, :destroy, :update_packages]

  include Tess::BreadCrumbs
  include SearchableIndex
  include ActionView::Helpers::TextHelper

  # GET /materials
  # GET /materials?q=queryparam
  # GET /materials.json
  # GET /materials.json?q=queryparam

  def index
    respond_to do |format|
      format.json
      format.html
    end
  end
  #
  # def search query
  #   @materials = Material.search { fulltext query }
  # end

  # GET /materials/1
  # GET /materials/1.json
  def show
  end

  # GET /materials/new
  def new
    authorize Material
    @material = Material.new
  end

  # GET /materials/1/edit
  def edit
    authorize @material
    tools_response = open "#{ExternalResource::BIOTOOLS_BASE}/api/tool?q=" + URI.escape(@material.title)
    tools_response = tools_response.read
  end

  # POST /materials/check_title
  # POST /materials/check_title.json
  def check_exists
    @material = params[:url].blank? ? nil : Material.find_by_url(params[:url])

    if @material
      respond_to do |format|
        format.html { redirect_to @material }
        #format.json { render json: @material }
        format.json { render :show, location: @material }
      end
    else
      respond_to do |format|
        format.html { render :nothing => true, :status => 200, :content_type => 'text/html' }
        format.json { render :nothing => true, :status => 200, :content_type => 'application/json' }
      end
    end
  end

  # POST /materials
  # POST /materials.json
  def create
    authorize Material
    @material = Material.new(material_params)
    @material.user = current_user

    respond_to do |format|
      if @material.save
        @material.create_activity :create, owner: current_user
        look_for_topics(@material)
        #current_user.materials << @material
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
        # If it's being updated and has an edit suggestion then, for now, this can be removed so it doesn't
        # suggest the same topics on every edit.
        # TODO: Consider whether this is proper behaviour or whether a user should explicitly delete this
        # TODO: suggestion, somehow.
        if @material.edit_suggestion
          #suggestion  = @material.edit_suggestion
          #@material.edit_suggestion = nil
          #suggestion.delete
        end
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

  # POST /materials/1/update_packages
  # POST /materials/1/update_packages.json
  def update_packages
    # Go through each selected package
    # and update its resources to include this material.
    # Go through each other package that is not selected and remove this material from it.
    packages = params[:material][:package_ids].select{|p| !p.blank?}
    packages = packages.collect{|package| Package.find_by_id(package)}
    packages_to_remove = @material.packages - packages
    packages.each do |package|
      package.update_resources_by_id((package.materials + [@material.id]).uniq, nil)
    end
    packages_to_remove.each do |package|
      package.update_resources_by_id((package.materials.collect{|x| x.id} - [@material.id]).uniq, nil)
    end
    flash[:notice] = "Material has been included in #{pluralize(packages.count, 'package')}"
    redirect_to @material
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_material
    @material = Material.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def material_params
    params.require(:material).permit(:id, :title, :url, :short_description, :long_description, :doi,:last_scraped, :scraper_record,
                                     :remote_created_date,  :remote_updated_date, {:package_ids => []},
                                     :content_provider_id, {:keywords => []},
                                     {:scientific_topic_names => []},
                                     :licence, :difficulty_level, {:contributors => []},
                                     {:authors => []}, {:target_audience => []}, {:node_ids => []}, {:node_names => []},
                                     external_resources_attributes: [:id, :url, :title, :_destroy], event_ids: [])
  end

  #  Run a sidekiq task here to find suggested scientific topics
  def look_for_topics(material)
    # Something like this:
    if material.scientific_topic_names.length == 0
      EditSuggestionWorker.perform_in(1.minute,material.id)
    end
  end

end
