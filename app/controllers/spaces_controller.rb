# The controller for actions related to the Spaces model
class SpacesController < ApplicationController
  before_action :ensure_feature_enabled
  before_action :set_space, only: [:show, :edit, :update, :destroy]
  before_action :set_breadcrumbs

  # GET /spaces
  def index
    @spaces = Space.all
    respond_to do |format|
      format.html
    end
  end

  # GET /spaces/1
  def show
    respond_to do |format|
      format.html
    end
  end

  # GET /spaces/new
  def new
    authorize Space
    @space = Space.new
  end

  # GET /spaces/1/edit
  def edit
    authorize @space
  end

  # POST /spaces
  def create
    authorize Space
    @space = Space.new(space_params)
    @space.user = current_user

    respond_to do |format|
      if @space.save
        @space.create_activity :create, owner: current_user
        format.html { redirect_to @space, notice: 'Space was successfully created.' }
      else
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /spaces/1
  def update
    authorize @space
    respond_to do |format|
      if @space.update(space_params)
        @space.create_activity(:update, owner: current_user) if @space.log_update_activity?
        format.html { redirect_to @space, notice: 'Space was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  # DELETE /spaces/1
  def destroy
    authorize @space
    @space.create_activity :destroy, owner: current_user
    @space.destroy
    respond_to do |format|
      format.html { redirect_to spaces_path, notice: 'Space was successfully deleted.' }
    end
  end

  private

  def set_space
    @space = Space.find(params[:id])
  end

  def space_params
    permitted = [:title, :description, :theme, :image, :image_url, { administrator_ids: [] }, { enabled_features: [] }]
    permitted += [:host] if current_user.is_admin?
    params.require(:space).permit(*permitted)
  end
end
