class NodesController < ApplicationController
  before_action :set_node, only: [:show, :edit, :update, :destroy]

  include TeSS::BreadCrumbs

  # GET /nodes
  # GET /nodes.json
  def index
    @nodes = Node.all
  end

  # GET /nodes/1
  # GET /nodes/1.json
  def show
  end

  # GET /nodes/new
  def new
    authorize Node
    @node = Node.new
  end

  # GET /nodes/1/edit
  def edit
    authorize @node
  end

  # POST /nodes
  # POST /nodes.json
  def create
    authorize Node
    @node = Node.new(node_params)
    @node.user = current_user

    respond_to do |format|
      if @node.save
        @node.create_activity :create, owner: current_user
        format.html { redirect_to @node, notice: 'Node was successfully created.' }
        format.json { render :show, status: :created, location: @node }
      else
        format.html { render :new }
        format.json { render json: @node.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /nodes/1
  # PATCH/PUT /nodes/1.json
  def update
    authorize @node
    respond_to do |format|
      if @node.update(node_params)
        @node.create_activity :update, owner: current_user
        format.html { redirect_to @node, notice: 'Node was successfully updated.' }
        format.json { render :show, status: :ok, location: @node }
      else
        format.html { render :edit }
        format.json { render json: @node.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /nodes/1
  # DELETE /nodes/1.json
  def destroy
    authorize @node
    @node.create_activity :destroy, owner: current_user
    @node.destroy
    respond_to do |format|
      format.html { redirect_to nodes_url, notice: 'Node was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_node
      @node = Node.friendly.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def node_params
      params.require(:node).permit(:name, :member_status, :country_code, :home_page, :institutions, :trc, :trc_email, :trc, :staff, :twitter, :carousel_images)
    end
end
