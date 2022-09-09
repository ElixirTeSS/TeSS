# The controller for actions related to the Collection model
class CollectionsController < ApplicationController
  before_action :set_collection, only: %i[show edit curate add_item remove_item update destroy]
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
    since = params[:since] || @collection.send(@item_class.table_name).maximum(:created_at) || Time.at(0)
    @items = @item_class.where('created_at > ?', since).order('created_at ASC')
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

  def item_class
    raise ActiveRecord::RecordNotFound unless allowed_item_types.include? params[:type]

    params[:type].constantize
  end

  def allowed_item_types
    allowed = []
    allowed << 'Event' if TeSS::Config.feature['events']
    allowed << 'Material' if TeSS::Config.feature['materials']
    allowed
  end
end
