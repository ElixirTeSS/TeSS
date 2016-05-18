class NodesController < ApplicationController
  before_action :set_node, only: [:show, :edit, :update, :destroy]
  before_action :set_params, :only => :index

  include TeSS::BreadCrumbs

  helper 'search'

  # GET /nodes
  # GET /nodes.json
  def index
    @facet_fields = Node::FACET_FIELDS
    if SOLR_ENABLED
      @nodes = solr_search(Node, @search_params, @facet_fields, @facet_params, @page, @sort_by)
    else
      @nodes = Node.all
    end
    respond_to do |format|
      format.json { render json: @nodes.results }
      format.html
    end
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

  def set_params
    params.permit(:q, :page, :sort, Node::FACET_FIELDS, Node::FACET_FIELDS.map{|f| "#{f}_all"})
    @search_params = params[:q] || ''
    @facet_params = {}
    @sort_by = params[:sort]
    Node::FACET_FIELDS.each {|facet_title| @facet_params[facet_title] = params[facet_title] if !params[facet_title].nil? }
    @page = params[:page] || 1
  end

end
