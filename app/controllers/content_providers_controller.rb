class ContentProvidersController < ApplicationController

  before_action :set_content_provider, only: [:show, :edit, :update, :destroy]
  before_action :set_search_params, :only => :index
  before_action :set_facet_params, :only => :index

  include TeSS::BreadCrumbs

  @@facet_fields = %w( keywords )

  def index
    @facet_fields = @@facet_fields
    if SOLR_ENABLED
      @content_providers = solr_search(ContentProvider, @search_params, @@facet_fields, @facet_params)
    else
      @content_providers = Package.all
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render :json => @content_provider }
    end
  end

  def new
    @content_provider = ContentProvider.new
  end

  def edit
  end

  # POST /events/check_exists
  # POST /events/check_exists.json
  def check_exists
    title = params[:title]
    url = params[:url]
    if !title.blank? or !url.blank?
      @content_provider = ContentProvider.find_by_url(url)
      if @content_provider.nil?
        @content_provider = ContentProvider.find_by_title(title)
      end
    else
      respond_to do |format|
        format.html { render :nothing => true, :status => 200, :content_type => 'text/html' }
        format.json { render :nothing => true, :status => 200, :content_type => 'application/json' }
      end
    end

    if @content_provider
      respond_to do |format|
        format.html { redirect_to @content_provider }
        format.json { render :show, location: @content_provider }
      end
    else
      respond_to do |format|
        format.html { render :nothing => true, :status => 200, :content_type => 'text/html' }
        format.json { render :nothing => true, :status => 200, :content_type => 'application/json' }
      end
    end
  end

  def create
    @content_provider = ContentProvider.new(content_provider_params)

    respond_to do |format|
      if @content_provider.save
        @content_provider.create_activity :create, owner: current_user
        format.html { redirect_to @content_provider, notice: 'Content Provider was successfully created.' }
        format.json { render :show, status: :created, location: @content_provider }
      else
        format.html { render :new }
        format.json { render json: @content_provider.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @content_provider.update(content_provider_params)
        @content_provider.create_activity :update, owner: current_user
        format.html { redirect_to @content_provider, notice: 'Content Provider was successfully updated.' }
        format.json { render :show, status: :ok, location: @content_provider }
      else
        format.html { render :edit }
        format.json { render json: @content_provider.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @content_provider.create_activity :destroy, owner: current_user
    @content_provider.destroy
    respond_to do |format|
      format.html { redirect_to content_providers_url, notice: 'Content Provider was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_content_provider
    @content_provider = ContentProvider.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def content_provider_params
    params.require(:content_provider).permit(:title, :url, :image_url, :description, :id,
                                             {:keywords => []}, :remote_updated_date, :remote_created_date, :local_updated_date, :remote_updated_date)
  end


  def set_search_params
    params.permit(:q)
    @search_params = params[:q] || ''
  end

  def set_facet_params
    params.permit(@@facet_fields, @@facet_fields.map { |f| "#{f}_all" })
    @facet_params = {}
    @@facet_fields.each { |facet_title| @facet_params[facet_title] = params[facet_title] if !params[facet_title].nil? }
  end

end

