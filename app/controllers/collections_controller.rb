# The controller for actions related to the Collection model
class CollectionsController < ApplicationController
  before_action :feature_enabled?
  before_action :set_collection, only: %i[show edit curate update_curation add_item remove_item update destroy]
  before_action :set_breadcrumbs

  include SearchableIndex

  # GET /collections
  # GET /collections.json
  def index
  end

  # GET /collections/1
  # GET /collections/1.json
  def show
    authorize @collection
  end

  # GET /collections/new
  def new
    authorize Collection
    @collection = Collection.new
  end

  # GET /collections/1/edit
  def edit
    authorize @collection
  end

  # GET /collections/1/curate_#{type}?since=#{DateTime}
  def curate
    authorize @collection

    # the default date range is given by the highest created_at date of the collection
    @item_class = item_class
    @since = params[:since]&.to_date || @collection.send(@item_class.table_name).maximum(:created_at) || Time.at(0)
    @items = @item_class.where('created_at >= ?', @since).order('created_at ASC')
    # If we are looking at Events, only show those that have not yet ended unless params[:past] is set
    @items = @items.where('"events"."end" > ?', Time.zone.now) unless (@show_past = params[:past]) || params[:type] != 'Event'
  end

  # PATCH/PUT /collections/1/curate_#{type}
  def update_curation
    # We need a separate method since we only also need to remove deselected items.
    authorize @collection

    respond_to do |format|
      if update_collection_items!
        @collection.create_activity(:update, owner: current_user) if @collection.log_update_activity?
        format.html { redirect_to @collection, notice: 'Collection was successfully updated.' }
        format.json { render :show, status: :ok, location: @collection }
      else
        @item_class = item_class
        @since = @item_class.find(params[:reviewed_item_ids].last).created_at
        @items = @item_class.where('created_at >= ?', @since).order('created_at ASC')
        format.html { render :curate }
        format.json { render json: @collection.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /collections
  # POST /collections.json
  def create
    authorize Collection
    @collection = Collection.new(collection_params)
    @collection.user = current_user

    respond_to do |format|
      if @collection.save
        @collection.create_activity :create, owner: current_user
        current_user.collections << @collection
        format.html { redirect_to @collection, notice: 'Collection was successfully created.' }
        format.json { render :show, status: :created, location: @collection }
      else
        format.html { render :new }
        format.json { render json: @collection.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /collections/1
  # PATCH/PUT /collections/1.json
  def update
    authorize @collection
    respond_to do |format|
      if @collection.update(collection_params)
        @collection.create_activity(:update, owner: current_user) if @collection.log_update_activity?
        format.html { redirect_to @collection, notice: 'Collection was successfully updated.' }
        format.json { render :show, status: :ok, location: @collection }
      else
        format.html { render :edit }
        format.json { render json: @collection.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /collections/1
  # DELETE /collections/1.json
  def destroy
    authorize @collection
    @collection.create_activity :destroy, owner: current_user
    @collection.destroy
    respond_to do |format|
      format.html { redirect_to collections_url, notice: 'Collection was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_collection
    @collection = Collection.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def collection_params
    params.require(:collection).permit(:title, :description, :image, :image_url, :public, {:keywords => []}, {:material_ids => []}, {:event_ids => []})
  end

  # Filter collection items based on a type
  def item_class
    case params[:type]
    when 'Event'
      return Event if TeSS::Config.feature['events']
    when 'Material'
      return Material if TeSS::Config.feature['materials']
    end

    raise ActiveRecord::AccessDenied
  end

  # Delete the reviewed but unselected items (if they exist)
  # There is no real performance hit with loading the model,
  # since they need to be SOLR-indexed anyway.
  # therefore we can skip doing the bulk inserts, and just use ActiveRecord.
  # (could work around that with partial updates, but not necessary now)
  def update_collection_items!
    collection_items.delete(items_to_remove)
    collection_items << items_to_add
  end

  def collection_items
    @collection.send(item_class.table_name)
  end

  # Find all items which were selected but are not yet in this collection
  def items_to_add
    # See https://pganalyze.com/blog/active-record-subqueries-rails
    # (could also be done with an anti-join pattern, but troublesome )
    item_class.where(id: params[:item_ids])
              .where('NOT EXISTS (:collection_items)',
                     collection_items: collection_items.select('1'))
  end

  # Find all items which were not selected but are in the collection
  def items_to_remove
    item_class.where(id: params[:reviewed_item_ids])
              .where.not(id: params[:item_ids])
              .where('EXISTS (:collection_items)',
                     collection_items: collection_items.select('1'))
  end
end
