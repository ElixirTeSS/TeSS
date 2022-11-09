class SourcesController < ApplicationController

  before_action :set_source, only: [:show, :edit, :update, :destroy]
  before_action :set_content_provider
  before_action :set_content_provider_for_admin, only: [:create, :update]
  before_action :set_breadcrumbs

  include SearchableIndex

  # GET /sources
  # GET /sources.json
  def index
    authorize Source
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
    @source = @content_provider.sources.build(source_params)
    @source.user = current_user

    respond_to do |format|
      if @source.save
        @source.create_activity :create, owner: current_user
        current_user.sources << @source
        format.html { redirect_to @source, notice: 'Source was successfully created.' }
        format.json { render :show, status: :created, location: @source }
      else
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
    @source.destroy
    respond_to do |format|
      format.html { redirect_to sources_url, notice: 'Source was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def set_content_provider_for_admin
    if policy(Source).administration?
      @content_provider ||= ContentProvider.friendly.find_by_id(source_params[:content_provider_id])
    end
  end

  def set_content_provider
    @content_provider ||= ContentProvider.friendly.find_by_id(params[:content_provider_id])
    unless policy(Source).administration? && ['index', 'create', 'new'].include?(action_name)
      raise ActiveRecord::RecordNotFound unless @content_provider
      authorize @content_provider, :manage?
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_source
    @source = Source.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def source_params
    permitted = [:url, :method, :token, :enabled]
    permitted << :approval_status if policy(Source).approve?
    permitted << :content_provider_id if policy(Source).index?

    params.require(:source).permit(permitted)
  end

  def set_breadcrumbs
    if @content_provider
      add_base_breadcrumbs('content_providers')
      add_show_breadcrumb(@content_provider)
      add_breadcrumb 'New Source', new_content_provider_source_path(@content_provider)
    else
      super
    end
  end

end
