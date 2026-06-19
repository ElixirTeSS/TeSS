class GroupsController < ApplicationController
  before_action :set_group, only: %i[ show edit update destroy ]

  # GET /groups
  def index
    @groups = Group.all
  end

  # GET /groups/1
  def show
  end

  # GET /groups/new
  def new
    authorize Group
    @group = Group.new
  end

  # GET /groups/1/edit
  def edit
    authorize @group
  end

  def create
    @group = Group.new(group_params.except(:owner_ids))

    if @group.save
      sync_owners
      redirect_to @group, notice: "Group was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @group.update(group_params.except(:owner_ids))
      sync_owners
      redirect_to @group, notice: "Group was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /groups/1
  def destroy
    authorize @group
    @group.destroy!

    respond_to do |format|
      format.html { redirect_to groups_path, status: :see_other, notice: "Group was successfully destroyed." }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_group
      @group = Group.find(params[:id])
    end

    def group_params
      params.require(:group).permit(:title, user_ids: [], owner_ids: [])
    end

    def sync_owners
      owner_ids = (params.dig(:group, :owner_ids) || []).map(&:to_i)
      @group.group_memberships.each do |membership|
        membership.update(owner: owner_ids.include?(membership.user_id))
      end
    end
end
