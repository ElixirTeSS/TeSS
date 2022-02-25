class CollectionsController < ApplicationController
  before_action :set_Collection, only: [:show, :edit, :update, :destroy]
  before_action :set_breadcrumbs

  include SearchableIndex

  # GET /Collections
  # GET /Collections.json
  def index
  end

  # GET /Collections/1
  # GET /Collections/1.json
  def show
    authorize @Collection
  end

  # GET /Collections/new
  def new
    authorize Collection
    @Collection = Collection.new
  end

  # GET /Collections/1/edit
  def edit
    authorize @Collection
  end

  # POST /Collections
  # POST /Collections.json
  def create
    authorize Collection
    @Collection = Collection.new(Collection_params)
    @Collection.user = current_user

    respond_to do |format|
      if @Collection.save
        @Collection.create_activity :create, owner: current_user
        current_user.Collections << @Collection
        format.html { redirect_to @Collection, notice: 'Collection was successfully created.' }
        format.json { render :show, status: :created, location: @Collection }
      else
        format.html { render :new }
        format.json { render json: @Collection.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /Collections/1
  # PATCH/PUT /Collections/1.json
  def update
    authorize @Collection
    respond_to do |format|
      if @Collection.update(Collection_params)
        @Collection.create_activity(:update, owner: current_user) if @Collection.log_update_activity?
        format.html { redirect_to @Collection, notice: 'Collection was successfully updated.' }
        format.json { render :show, status: :ok, location: @Collection }
      else
        format.html { render :edit }
        format.json { render json: @Collection.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /Collections/1
  # DELETE /Collections/1.json
  def destroy
    authorize @Collection
    @Collection.create_activity :destroy, owner: current_user
    @Collection.destroy
    respond_to do |format|
      format.html { redirect_to Collections_url, notice: 'Collection was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
    def set_Collection
      @Collection = Collection.friendly.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def Collection_params
      params.require(:Collection).permit(:title, :description, :image, :image_url, :public, {:keywords => []}, {:material_ids => []}, {:event_ids => []})
    end
end
