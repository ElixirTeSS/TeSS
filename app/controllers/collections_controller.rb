class CollectionsController < ApplicationController
  before_action :set_collection, only: [:show, :edit, :update, :destroy]
  before_action :set_breadcrumbs

  include SearchableIndex

  # GET /Collections
  # GET /Collections.json
  def index
  end

  # GET /Collections/1
  # GET /Collections/1.json
  def show
    authorize @collection
  end

  # GET /Collections/new
  def new
    authorize Collection
    @collection = Collection.new
  end

  # GET /Collections/1/edit
  def edit
    authorize @collection
  end

  # POST /Collections
  # POST /Collections.json
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

  # PATCH/PUT /Collections/1
  # PATCH/PUT /Collections/1.json
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

  # DELETE /Collections/1
  # DELETE /Collections/1.json
  def destroy
    authorize @collection
    @collection.create_activity :destroy, owner: current_user
    @collection.destroy
    respond_to do |format|
      format.html { redirect_to Collections_url, notice: 'Collection was successfully destroyed.' }
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
end
