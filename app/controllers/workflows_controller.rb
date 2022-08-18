# The controller for actions related to the Workflows model
class WorkflowsController < ApplicationController

  layout 'application'

  before_action :set_workflow, only: [:show, :edit, :update, :destroy, :fork, :embed]
  before_action :set_breadcrumbs
  after_action :allow_embedding, only: [:embed]

  include SearchableIndex

  # GET /workflows
  # GET /workflows.json
  def index
    respond_to do |format|
      format.html
      format.json
      format.json_api { render({ json: @workflows }.merge(api_collection_properties)) }
    end
  end

  # GET /workflows/1
  # GET /workflows/1.json
  def show
    @skip_flash_messages_in_header = true # we will handle flash messages in the 'workflows' layout
    respond_to do |format|
      format.html { render layout: 'workflows' }
      format.json
      format.json_api { render json: @workflow }
    end
  end

  # GET /workflows/new
  def new
    authorize Workflow
    @workflow = Workflow.new
    render layout: 'workflows'
  end

  # GET /workflows/1/edit
  def edit
    authorize @workflow
    render layout: 'workflows'
  end

  # POST /workflows
  # POST /workflows.json
  def create
    authorize Workflow
    @workflow = Workflow.new(workflow_params)
    @workflow.user = current_user

    respond_to do |format|
      if @workflow.save
        @workflow.create_activity :create, owner: current_user
        look_for_topics(@workflow)
        format.html { redirect_to @workflow, notice: 'Workflow was successfully created.' }
        format.json { render :show, status: :created, location: @workflow }
      else
        format.html { render :new }
        format.json { render json: @workflow.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /workflows/1
  # PATCH/PUT /workflows/1.json
  def update
    authorize @workflow
    respond_to do |format|
      if @workflow.update(workflow_params)
        @workflow.create_activity(:update, owner: current_user) if @workflow.log_update_activity?
        format.html { redirect_to @workflow, notice: 'Workflow was successfully updated.' }
        format.json { render :show, status: :ok, location: @workflow }
      else
        format.html { render :edit }
        format.json { render json: @workflow.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /workflows/1
  # DELETE /workflows/1.json
  def destroy
    authorize @workflow
    @workflow.create_activity :destroy, owner: current_user
    @workflow.destroy
    respond_to do |format|
      format.html { redirect_to workflows_url, notice: 'Workflow was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def fork
    @workflow = @workflow.new_fork(current_user)

    respond_to do |format|
      format.html { render :new }
    end
  end

  def embed
    authorize @workflow, :show?
    render layout: 'embed'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_workflow
    @workflow = Workflow.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def workflow_params
    params.require(:workflow).permit(:title, :description, :user_id, :workflow_content, :doi,
                                     :remote_created_date,  :remote_updated_date, { keywords: [] },
                                     { scientific_topic_names: [] }, { scientific_topic_uris: [] }, :licence,
                                     :difficulty_level, { contributors: [] }, { authors: [] }, { target_audience: [] },
                                     :hide_child_nodes, :public)
  end

end
