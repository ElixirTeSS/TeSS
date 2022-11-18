class SourcesController < ApplicationController
  before_action :set_source, except: [:index, :new, :create]
  before_action :set_content_provider, except: :index
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
    @source = @content_provider.sources.build
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
    @source.create_activity :destroy, owner: current_user
    @source.destroy
    respond_to do |format|
      format.html { redirect_to policy(Source).index? ? sources_path : content_provider_path(@content_provider),
                                notice: 'Source was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  def test
    authorize @source, :manage?
    job_id = SourceTestWorker.perform_async(@source.id)
    @source.test_job_id = job_id

    respond_to do |format|
      format.json { render json: { id: job_id }}
    end
  end

  def test_results
    authorize @source, :manage?
    test_results = @source.test_results
    if test_results.nil?
      head :not_found
    else
      render partial: 'sources/test_results', object: test_results
    end
  end

  def request_approval
    authorize @source

    if @source.approval_requested?
      flash[:error] = 'Approval request has already been submitted.'
    elsif @source.approved?
      flash[:error] = 'Already approved.'
    else
      @source.request_approval
      flash[:notice] = 'Approval request was sent successfully.'
    end

    respond_to do |format|
      format.html { redirect_to @source }
    end
  end

  private

  def set_source
    @source = Source.find(params[:id])
  end

  def set_content_provider
    @content_provider = @source.content_provider if @source
    @content_provider ||= ContentProvider.friendly.find(params[:content_provider_id])
    authorize @content_provider, :manage?
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
      add_breadcrumb 'Sources'

      if params[:id]
        add_breadcrumb @source.title, content_provider_source_path(@content_provider, @source) if (@source && !@source.new_record?)
        add_breadcrumb action_name.capitalize.humanize, request.path unless action_name == 'show'
      elsif action_name != 'index'
        add_breadcrumb action_name.capitalize.humanize, request.path
      end
    else
      super
    end
  end

end
