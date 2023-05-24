# frozen_string_literal: true

require 'tzinfo'

# The controller for actions related to the Events model
class EventsController < ApplicationController
  before_action :feature_enabled?
  before_action :set_event, only: [:show, :edit, :clone, :update, :destroy, :update_collections, :add_term, :reject_term,
                                   :redirect, :report, :update_report, :add_data, :reject_data]
  before_action :set_breadcrumbs
  before_action :disable_pagination, only: :index, if: lambda { |controller|
                                                         controller.request.format.ics? or controller.request.format.csv? or controller.request.format.rss?
                                                       }

  include SearchableIndex
  include ActionView::Helpers::TextHelper
  include FieldLockEnforcement
  include TopicCuration

  # GET /events
  # GET /events.json
  def index
    @bioschemas = @events.flat_map(&:to_bioschemas)
    respond_to do |format|
      format.html
      format.json
      format.json_api { render({ json: @events }.merge(api_collection_properties)) }
      format.csv
      format.ics
      format.rss
    end
  end

  # GET /events/1
  # GET /events/1.json
  # GET /events/1.ics
  def show
    @bioschemas = @event.to_bioschemas
    respond_to do |format|
      format.html
      format.json
      format.json_api { render json: @event }
      format.ics do
        send_data @event.to_ical, type: 'text/calendar', disposition: 'attachment', filename: "#{@event.slug}.ics"
      end
    end
  end

  # GET /events/new
  def new
    authorize Event
    @event = Event.new(start: DateTime.now.change(hour: 9),
                       end: DateTime.now.change(hour: 17))
  end

  # GET /events/1/clone
  def clone
    authorize @event
    @event = @event.duplicate
    render :new
  end

  # GET /events/1/edit
  def edit
    authorize @event
  end

  # GET /events/1/report
  def report
    authorize @event, :edit_report?
  end

  # PATCH /events/1/report
  def update_report
    authorize @event, :edit_report?

    respond_to do |format|
      if @event.update(event_report_params)
        @event.create_activity(:report, owner: current_user) if @event.log_update_activity?

        format.html { redirect_to event_path(@event, anchor: 'report'), notice: 'Event report successfully updated.' }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { render :report }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /events/check_exists
  # POST /events/check_exists.json
  def check_exists
    @event = Event.check_exists(event_params)

    if @event
      respond_to do |format|
        format.html { redirect_to @event }
        format.json { render :show, location: @event }
      end
    else
      respond_to do |format|
        format.html { render nothing: true, status: :ok, content_type: 'text/html' }
        format.json { render json: {}, status: :ok, content_type: 'application/json' }
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

  # POST /events/1/update_collections
  # POST /events/1/update_collections.json
  def update_collections
    # Go through each selected collection
    # and update its resources to include this one.
    # Go through each other collection
    collections = params[:event][:collection_ids].select(&:present?)
    collections = collections.collect { |collection| Collection.find_by(id: collection) }
    collections_to_remove = @event.collections - collections
    collections.each do |collection|
      collection.update_resources_by_id(nil, (collection.events + [@event.id]).uniq)
    end
    collections_to_remove.each do |collection|
      collection.update_resources_by_id(nil, (collection.events.collect(&:id) - [@event.id]).uniq)
    end
    flash[:notice] = "Event has been included in #{pluralize(collections.count, 'collection')}"
    redirect_to @event
  end

  def redirect
    @event.widget_logs.create(widget_name: params[:widget],
                              action: "#{controller_name}##{action_name}",
                              data: @event.url, params: params)

    redirect_to @event.url
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_event
    @event = Event.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def event_params
    params.require(:event).permit(:external_id, :title, :subtitle, :url, :organizer, :last_scraped, :scraper_record,
                                  :description, { scientific_topic_names: [] }, { scientific_topic_uris: [] },
                                  { operation_names: [] }, { operation_uris: [] }, { event_types: [] },
                                  { keywords: [] }, { fields: [] }, :start, :end, :duration, { sponsors: [] },
                                  :online, :venue, :city, :county, :country, :postcode, :latitude, :longitude,
                                  :timezone, :content_provider_id, { collection_ids: [] }, { node_ids: [] },
                                  { node_names: [] }, { target_audience: [] }, { eligibility: [] },
                                  { host_institutions: [] }, :capacity, :contact, :recognition, :learning_objectives,
                                  :prerequisites, :tech_requirements, :cost_basis, :cost_value, :cost_currency,
                                  external_resources_attributes: [:id, :url, :title, :_destroy], material_ids: [],
                                  locked_fields: [])
  end

  def event_report_params
    params.require(:event).permit(:funding, :attendee_count, :applicant_count, :trainer_count, :feedback, :notes)
  end

  def disable_pagination
    params[:per_page] = 2**10
  end
end
