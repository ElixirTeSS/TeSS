# The controller for actions related to the Spaces model
class SpacesController < ApplicationController
  before_action :ensure_feature_enabled
  before_action :set_space, only: [:show, :edit, :update, :destroy]
  before_action :set_breadcrumbs

  # GET /spaces
  #
  # Lists every Space visible to the current user (i.e. for which
  # SpacePolicy#shown? returns +true+).
  def index
    @spaces = Space.all.select { |space| policy(space).shown? }
    respond_to do |format|
      format.html
      format.json { render json: @groups.as_json(only: [:id, :title]) }
    end
  end

  # GET /spaces/1
  #
  # Shows a single space. Requires authorization via SpacePolicy#show?.
  def show
    authorize @space
    respond_to do |format|
      format.html
    end
  end

  # GET /spaces/new
  #
  # Builds a new, unsaved Space for the creation form. Requires
  # authorization via SpacePolicy#new?.
  def new
    authorize Space
    @space = Space.new
  end

  # GET /spaces/1/edit
  #
  # Requires authorization via SpacePolicy#edit?.
  def edit
    authorize @space
  end

  # POST /spaces
  #
  # Creates a new space owned by the current user, from #space_params.
  # Requires authorization via SpacePolicy#create?. Logs a +:create+
  # PublicActivity entry on success.
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
  #
  # Updates the space from #space_params. Requires authorization via
  # SpacePolicy#update?. Logs a +:update+ PublicActivity entry on success,
  # if Space#log_update_activity? allows it.
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
  #
  # Destroys the space. Requires authorization via SpacePolicy#destroy?.
  # Logs a +:destroy+ PublicActivity entry before deletion.
  def destroy
    authorize @space
    @space.create_activity :destroy, owner: current_user
    @space.destroy
    respond_to do |format|
      format.html { redirect_to spaces_path, notice: 'Space was successfully deleted.' }
    end
  end

  private

  # Loads the Space identified by <tt>params[:id]</tt> into +@space+.
  def set_space
    @space = Space.find(params[:id])
  end

  # Returns:: the strong-parameters Hash permitted for Space creation and
  #           update. Includes +:host+ only when the current user is an
  #           admin.
  def space_params
    permitted = [:title, :description, :theme, :image, :image_url, :is_private, { administrator_ids: [] }, { enabled_features: [] }, { group_ids: [] }]
    permitted += [:host] if current_user.is_admin?
    params.require(:space).permit(*permitted)
  end
end
