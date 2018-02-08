class ContentProvidersController < ApplicationController
  before_action :set_content_provider, only: [:show, :edit, :update, :destroy, :import, :scrape, :scraper_results, :bulk_create]
  before_action :set_breadcrumbs

  include SearchableIndex

  def index
    respond_to do |format|
      format.html
      format.json
      format.json_api { render({ json: @content_providers }.merge(api_collection_properties)) }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json
      format.json_api { render json: @content_provider }
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
    @content_provider = ContentProvider.check_exists(content_provider_params)

    if @content_provider
      respond_to do |format|
        format.html { redirect_to @content_provider }
        format.json { render :show, location: @content_provider }
      end
    else
      respond_to do |format|
        format.html { render :nothing => true, :status => 200, :content_type => 'text/html' }
        format.json { render json: {}, :status => 200, :content_type => 'application/json' }
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
        @content_provider.create_activity(:update, owner: current_user) if @content_provider.log_update_activity?
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

  def import

  end

  def bulk_create
    @events = []
    @materials = []

    (bulk_import_params[:events] || []).select { |_,e| e[:include_in_create] == '1'}.each do |_, event|
      @events << @content_provider.events.create(event)
    end

    (bulk_import_params[:materials] || []).select { |_, m| m[:include_in_create] == '1'}.each do |_, material|
      @materials << @content_provider.materials.create(material)
    end
  end

  def scrape
    job_id = ScraperWorker.perform_async(params[:url], params[:page_format])

    respond_to do |format|
      format.json { render json: { id: job_id }}
    end
  end

  def scraper_results
    yaml = File.read(File.join(Rails.root, 'tmp', "scrape_#{params[:job_id]}.yml"))
    data = YAML.load(yaml)
    @events = data[:events].map { |e| @content_provider.events.build(e) }
    @materials = data[:materials].map { |m| @content_provider.materials.build(m) }

    render partial: 'content_providers/scraper_results'
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_content_provider
    @content_provider = ContentProvider.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def content_provider_params
    # For calls to create/update content_provider - get the node id from node name, if node id is not passed
    if (params[:content_provider][:node_id].blank? && !params[:content_provider][:node_name].blank?)
      node = Node.find_by_name(params[:content_provider][:node_name])
      params[:content_provider][:node_id] = node.id unless node.blank?
    end
    params[:content_provider].delete :node_name

    permitted = [:title, :url, :image, :image_url, :description, :id, :content_provider_type, :node_id,
        {:keywords => []}, :remote_updated_date, :remote_created_date,
        :local_updated_date, :remote_updated_date, :node_name, :user_id]

    permitted.delete(:user_id) unless current_user && current_user.is_admin?

    params.require(:content_provider).permit(permitted)
  end

  def bulk_import_params
    params.require(:content_provider).permit(
        events: EventsController::PERMITTED_EVENT_PARAMS + [:include_in_create],
        materials: MaterialsController::PERMITTED_MATERIAL_PARAMS + [:include_in_create]
    )
  end
end
