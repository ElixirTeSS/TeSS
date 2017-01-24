class EventsController < ApplicationController
  before_action :set_event, only: [:show, :edit, :update, :destroy, :update_packages]
  before_action :disable_pagination, only: :index, if: lambda { |controller| controller.request.format.ics? or controller.request.format.csv? }

  include Tess::BreadCrumbs
  include SearchableIndex
  include ActionView::Helpers::TextHelper


  # GET /events
  # GET /events.json
  def index
    respond_to do |format|
      format.json
      format.html
      format.csv
      format.ics
    end
  end

  # GET /events/1
  # GET /events/1.json
  # GET /events/1.ics
  def show
    respond_to do |format|
      format.html
      format.json
      format.ics { render text: @event.to_ical }
    end
  end

  # GET /events/new
  def new
    authorize Event
    @event = Event.new
  end

  # GET /events/1/edit
  def edit
    authorize @event
  end

  # POST /events/check_exists
  # POST /events/check_exists.json
  def check_exists
    @event = params[:url].blank? ? nil : Event.find_by_url(params[:url])

    if @event
      respond_to do |format|
        format.html { redirect_to @event }
        format.json { render :show, location: @event }
      end
    else
      respond_to do |format|
        format.html { render :nothing => true, :status => 200, :content_type => 'text/html' }
        format.json { render :nothing => true, :status => 200, :content_type => 'application/json' }
      end
    end

  end

  # POST /events
  # POST /events.json
  def create
    authorize Event
    @event = Event.new(event_params)
    @event.user = current_user

    respond_to do |format|
      if @event.save
        @event.create_activity :create, owner: current_user
        #current_user.events << @event
        format.html { redirect_to @event, notice: 'Event was successfully created.' }
        format.json { render :show, status: :created, location: @event }
      else
        format.html { render :new }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /events/1
  # PATCH/PUT /events/1.json
  def update
    authorize @event
    respond_to do |format|
      if @event.update(event_params)
        @event.create_activity(:update, owner: current_user) if @event.log_update_activity?
        format.html { redirect_to @event, notice: 'Event was successfully updated.' }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { render :edit }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1
  # DELETE /events/1.json
  def destroy
    authorize @event
    @event.create_activity :destroy, owner: current_user
    @event.destroy
    respond_to do |format|
      format.html { redirect_to events_url, notice: 'Event was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # POST /events/1/update_packages
  # POST /events/1/update_packages.json
  def update_packages
    # Go through each selected package
    # and update its resources to include this one.
    # Go through each other package
    packages = params[:event][:package_ids].select{|p| !p.blank?}
    packages = packages.collect{|package| Package.find_by_id(package)}
    packages_to_remove = @event.packages - packages
    packages.each do |package|
      package.update_resources_by_id(nil, (package.events + [@event.id]).uniq)
    end
    packages_to_remove.each do |package|
      package.update_resources_by_id(nil, (package.events.collect{|x| x.id} - [@event.id]).uniq)
    end
    flash[:notice] = "Event has been included in #{pluralize(packages.count, 'package')}"
    redirect_to @event
  end

  protected

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_event
    @event = Event.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def event_params
    params.require(:event).permit(:external_id, :title, :subtitle, :url, :organizer, :last_scraped,
                                  :scraper_record, :description, {:scientific_topic_names => []}, {:event_types => []},
                                  {:keywords => []}, :start, :end, :sponsor, :online, :for_profit, :venue,
                                  :city, :county, :country, :postcode, :latitude, :longitude, :timezone,
                                  :content_provider_id, {:package_ids => []}, {:node_ids => []}, {:node_names => []},
                                  {:target_audience => []}, {:eligibility => []},
                                  {:host_institutions => []}, :capacity, :contact,
                                  external_resources_attributes: [:id, :url, :title, :_destroy], material_ids: [])
  end

  def disable_pagination
    params[:per_page] = 2 ** 10
  end

end
