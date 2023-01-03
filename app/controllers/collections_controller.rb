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

  # since we have not checked all items we have to do a little work
  # to add and remove only those that were checked now, with bulk queries
  # for good performance.
  def update_collection_items!
    # remove unselected ones, if any exist
    CollectionItem.where(collection_id: @collection.id,
                         resource_id: removed_collection_item_ids,
                         resource_type: item_class.name).delete_all # no callbacks!

    # bulk insert
    max_order = @collection.items.maximum(:order) || 0
    # https://www.bigbinary.com/blog/bulk-insert-support-in-rails-6#1-performing-bulk-inserts-by-skipping-duplicates
    CollectionItem.insert_all!(newly_selected_collection_item_ids.map do |id|
      max_order += 1
      { resource_id: id,
        resource_type: item_class.name,
        collection_id: @collection.id,
        order: max_order,
        created_at: Time.zone.now,
        updated_at: Time.zone.now }
    end) # also no callbacks

    # Now run a SOLR index on the added + removed entries
    Sunspot.index! item_class.where(id: newly_selected_collection_item_ids + removed_collection_item_ids) if TeSS::Config.solr_enabled
    true
  end

  def removed_collection_item_ids
    reviewed_collection_item_ids - selected_collection_item_ids
  end

  def selected_collection_item_ids
    Set.new(params[:item_ids]&.map(&:to_i))
  end

  def reviewed_collection_item_ids
    Set.new(params[:reviewed_item_ids]&.map(&:to_i))
  end

  def newly_selected_collection_item_ids
    selected_collection_item_ids - \
      Set.new(CollectionItem.where(collection_id: @collection.id,
                                   resource_id: selected_collection_item_ids,
                                   resource_type: item_class.name).pluck(:resource_id))
  end
end
