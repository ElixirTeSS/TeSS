class EventsController < ApplicationController
  before_action :set_event, only: [:show, :edit, :update, :destroy]

  #sets @search_params, @facet_params, and @page 
  before_action :set_params, :only => :index

  # Should allow token authentication for API calls
  acts_as_token_authentication_handler_for User, except: [:index, :show, :check_title] #only: [:new, :create, :edit, :update, :destroy]

  # User auth should be required in the web interface as well; it's here rather than in routes so that it
  # doesn't override the token auth, above.
  before_filter :authenticate_user!, except: [:index, :show, :check_title]

  # Should prevent forgery errors for JSON posts.
  skip_before_filter :verify_authenticity_token, :if => Proc.new { |c| c.request.format == 'application/json' }

  # GET /events
  # GET /events.json

  @@facet_fields = %w( city field category provider sponsor venue city country keyword )

  helper 'search'
  def index
    @facet_fields = @@facet_fields
    @events = solr_search(Event, @search_params, @@facet_fields, @facet_params, @page)
    respond_to do |format|
      format.json { render json: @events.results }
      format.html
    end
  end

  # GET /events/1
  # GET /events/1.json
  def show
  end

  # GET /events/new
  def new
    @event = Event.new
  end

  # GET /events/1/edit
  def edit
  end

  # POST /events/check_title
  # POST /events/check_title.json
  def check_title
    title = params[:title]
    if title
      @event = Event.find_by_title(title)
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
    @event = Event.new(event_params)

    respond_to do |format|
      if @event.save
        @event.create_activity :create
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
    respond_to do |format|
      if @event.update(event_params)
        @event.create_activity :update, owner: current_user
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
    @event.destroy
    respond_to do |format|
      format.html { redirect_to events_url, notice: 'Event was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def event_params
      params.require(:event).permit(:external_id, :title, :subtitle, :link, :provider, :description, {:field => []},
                                    {:category => []}, {:keyword => []}, :start, :end, :sponsor, :venue, :city, :county,
                                    :country, :postcode, :latitude, :longitude)
    end

    def set_params
      params.permit(:q, :page, @@facet_fields)
      @search_params = params[:q] || ''
      @facet_params = {}
      @@facet_fields.each {|facet_title| @facet_params[facet_title] = params[facet_title] if !params[facet_title].nil? }
      @page = params[:page] || 1
      if params[:include_expired]
          @facet_params['include_expired'] = true
      end
  end
end
