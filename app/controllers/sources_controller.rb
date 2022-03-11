class SourcesController < ApplicationController

  before_action :set_source, only: [:show, :edit, :update, :destroy]
  before_action :set_content_provider, only: [:index, :new, :create]
  before_action :set_breadcrumbs

  include SearchableIndex

  # GET /sources
  # GET /sources.json
  def index
    if @content_provider.nil?
      @sources = Source.all
    else
      @sources = Source.where(content_provider: @content_provider)
    end
    respond_to do |format|
      format.html
      format.json
      format.json_api { render({ json: @sources }.merge(api_collection_properties)) }
    end
  end

  # GET /sources/1
  # GET /sources/1.json
  def show
    authorize @source
  end

  # GET /sources/new
  def new
    authorize Source
    @source = Source.new
  end

  # GET /sources/1/edit
  def edit
    authorize @source
  end

  # POST /sources
  # POST /sources.json
  def create
    authorize Source
    @source = Source.new(source_params)
    @source.created_at = Time.now
    @source.user = current_user

    respond_to do |format|
      if @source.save
        @source.create_activity :create, owner: current_user
        current_user.sources << @source
        puts "Source save succeeded!"
        format.html { redirect_to @source, notice: 'Source was successfully created.' }
        format.json { render :show, status: :created, location: @source }
      else
        puts "Source save failed!"
        format.html { render :new }
        format.json { render json: @source.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /sources/check_exists
  # POST /sources/check_exists.json
  def check_exists
    @source = Source.check_exists(source_params)

    if @source
      respond_to do |format|
        format.html { redirect_to @source }
        format.json { render :show, location: @source }
      end
    else
      respond_to do |format|
        format.html { render :nothing => true, :status => 200, :content_type => 'text/html' }
        format.json { render json: {}, :status => 200, :content_type => 'application/json' }
      end
    end
  end

  # PATCH/PUT /sources/1
  # PATCH/PUT /sources/1.json
  def update
    authorize @source
    respond_to do |format|
      if @source.update(source_params)
        @source.create_activity(:update, owner: current_user) if @source.log_update_activity?
        format.html { redirect_to @source, notice: 'Source was successfully updated.' }
        format.json { render :show, status: :ok, location: @source }
      else
        format.html { render :edit }
        format.json { render json: @source.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sources/1
  # DELETE /sources/1.json
  def destroy
    authorize @source
    #@source.create_activity :destroy, owner: current_user
    @source.destroy
    respond_to do |format|
      format.html { redirect_to sources_url, notice: 'Source was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def set_content_provider
    @content_provider = nil
    slug = params[:content_provider]
    @content_provider = ContentProvider.find_by_slug(slug) unless slug.nil?
    if @content_provider.nil?
      id = params[:content_provider_id]
      @content_provider = ContentProvider.find(id) unless id.nil?
    end
    @content_provider
  end


  # Use callbacks to share common setup or constraints between actions.
  def set_source
    @source = Source.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def source_params
    params.require(:source).permit(:content_provider, :created_at,
                                   :url, :method, :resource_type)
  end

end
