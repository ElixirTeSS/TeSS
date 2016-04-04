class MaterialsController < ApplicationController
  require 'bread_crumbs'

  before_action :set_material, only: [:show, :edit, :update, :destroy]

  #sets @search_params, @facet_params, and @page 
  before_action :set_params, :only => :index

  include TeSS::BreadCrumbs

  # GET /materials
  # GET /materials?q=queryparam
  # GET /materials.json
  # GET /materials.json?q=queryparam

  @@facet_fields = %w(content_provider scientific_topic target_audience keywords licence difficulty_level authors contributors)

  helper 'search'

  def find_scientific_topics
    res = []
    if params[:scientific_topic_names]
      params.delete(:scientific_topic_names).each do |st_name|
        res << ScientificTopic.find_by_preferred_label(st_name)
      end
    end
    params[:scientific_topic] = res.compact.flatten.uniq if res and !res.empty?
  end

  def index
    @facet_fields = @@facet_fields
    if SOLR_ENABLED
      @materials = solr_search(Material, @search_params, @@facet_fields, @facet_params, @page, @sort_by)
    else
      @materials = Material.all
    end
    respond_to do |format|
      format.json { render json: @materials.results }
      format.html
    end
  end

  def search query
    @materials = Material.search { fulltext query } 
  end 


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
  end

  # POST /materials/check_title
  # POST /materials/check_title.json
  def check_exists
    title = params[:title]
    url = params[:url]
    if !title.blank? or !url.blank?
      @material = Material.find_by_url(url)
      if @material.nil?
        @material = Material.find_by_title(title)
      end
    else
      respond_to do |format|
        format.html { render :nothing => true, :status => 200, :content_type => 'text/html' }
        format.json { render :nothing => true, :status => 200, :content_type => 'application/json' }
      end
    end

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
    @material.user_id = current_user.id
    respond_to do |format|
      if @material.save
        @material.create_activity :create, owner: current_user
        current_user.materials << @material
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
        @material.create_activity :update, owner: current_user
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_material
      @material = Material.friendly.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def material_params
        mat_params = params.require(:material).permit(:title, :url, :short_description, :long_description, :doi, :remote_updated_date,
                                       :remote_created_date,  :remote_updated_date, {:package_ids => []}, :content_provider_id,
                                       :content_provider, {:keywords => []},
                                       {:scientific_topic_ids => []},
                                       {:scientific_topic_names => []},
                                       {:scientific_topic => []},
                                       :licence, :difficulty_level, {:contributors => []},
                                       {:authors=> []}, {:target_audience => []}  )

       if mat_params[:scientific_topic_ids].nil? or mat_params[:scientific_topic_ids].empty?
          mat_params[:scientific_topic_ids] = []
          names = [mat_params.delete('scientific_topic_names')].flatten
          if !names.empty?
            topics = names.collect{|name| ScientificTopic.find_by_preferred_label(name)}.flatten.compact.uniq
            topic_ids = topics.collect{|x|x.id}
          end
          mat_params[:scientific_topic_ids] = topic_ids
       end
       return mat_params
    end

    def set_params
      params.permit(:q, :page, :sort, @@facet_fields, @@facet_fields.map{|f| "#{f}_all"})
      @search_params = params[:q] || ''
      @facet_params = {}
      @sort_by = params[:sort]
      @@facet_fields.each {|facet_title| @facet_params[facet_title] = params[facet_title] if !params[facet_title].nil? }
      @page = params[:page] || 1
    end

end
