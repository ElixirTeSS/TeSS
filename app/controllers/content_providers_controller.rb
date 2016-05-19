class ContentProvidersController < ApplicationController
  before_action :set_content_provider, only: [:show, :edit, :update, :destroy]

  include TeSS::BreadCrumbs
  include SearchableIndex

  def index
    @content_providers = @index_resources
  end

  def show
    respond_to do |format|
      format.html
      format.json { render :json => @content_provider }
    end
  end

  def new
    authorize ContentProvider
    @content_provider = ContentProvider.new
  end

  def edit
    authorize @content_provider
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
    authorize ContentProvider
    @content_provider = ContentProvider.new(content_provider_params)
    @content_provider.user = current_user

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
    authorize @content_provider
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
    authorize @content_provider
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
end
