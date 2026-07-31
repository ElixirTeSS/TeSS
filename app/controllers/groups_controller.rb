# Controller for actions related to the Group model.
#
# Groups are collections of users; group membership (and ownership) is used
# elsewhere in the application, notably to control access to private Space
# objects.
class GroupsController < ApplicationController
  before_action :set_group, only: %i[ show edit update destroy ]
  before_action :set_breadcrumbs

  # GET /groups
  #
  # Lists all groups.
  def index
    @groups = Group.all
  end

  # GET /groups/1
  #
  # Shows a single group. Requires authorization via GroupPolicy#show?.
  def show
    authorize @group
  end

  # GET /groups/new
  #
  # Builds a new, unsaved Group for the creation form. Requires
  # authorization via GroupPolicy#new?.
  def new
    authorize Group
    @group = Group.new
  end

  # GET /groups/1/edit
  #
  # Requires authorization via GroupPolicy#edit?.
  def edit
    authorize @group
  end

  # POST /groups
  #
  # Creates a new group from #group_params, then synchronizes owner flags
  # on its memberships via #sync_owners. Requires authorization via
  # GroupPolicy#create?.
  def create
    authorize Group
    @group = Group.new(group_params.except(:owner_ids))

    if @group.save
      sync_owners
      redirect_to @group, notice: "Group was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /groups/1
  #
  # Updates the group from #group_params, then synchronizes owner flags on
  # its memberships via #sync_owners. Requires authorization via
  # GroupPolicy#update?.
  def update
    authorize @group
    if @group.update(group_params.except(:owner_ids))
      sync_owners
      redirect_to @group, notice: "Group was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /groups/1
  #
  # Destroys the group. Requires authorization via GroupPolicy#destroy?.
  # JSON requests are always forbidden (group deletion is HTML-only).
  def destroy
    authorize @group
    respond_to do |format|
      format.html do
        @group.destroy!
        redirect_to groups_path, status: :see_other, notice: "Group was successfully destroyed."
      end
      format.json { head :forbidden }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    #
    # Loads the Group identified by <tt>params[:id]</tt> into +@group+.
    def set_group
      @group = Group.find(params[:id])
    end

    # Returns:: the strong-parameters Hash permitted for Group creation and
    #           update (+:title+, +:user_ids+, +:owner_ids+).
    def group_params
      permitted = params.require(:group).permit(:title, user_ids: [], owner_ids: [])
      permitted[:user_ids] = permitted[:user_ids] if permitted.key?(:user_ids)
      permitted[:owner_ids] = permitted[:owner_ids] if permitted.key?(:owner_ids)
      permitted
    end

    # Synchronizes the +owner+ flag on each of +@group+'s memberships based
    # on the <tt>owner_ids</tt> submitted in the request parameters.
    def sync_owners
      owner_ids = (params.dig(:group, :owner_ids) || []).map(&:to_i)
      @group.group_memberships.each do |membership|
        membership.update(owner: owner_ids.include?(membership.user_id))
      end
    end
end
