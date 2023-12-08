class LearningPathsController < ApplicationController
  before_action :feature_enabled?
  before_action :set_learning_path, only: [:show, :edit, :update, :destroy]
  before_action :set_breadcrumbs

  include SearchableIndex

  def index
    # @bioschemas = @learning_paths.flat_map(&:to_bioschemas)
    respond_to do |format|
      format.html
      # format.json
      # format.json_api { render({ json: @learning_paths }.merge(api_collection_properties)) }
    end
  end

  def show
    # @bioschemas = @learning_path.to_bioschemas
    respond_to do |format|
      format.html
      # format.json
      # format.json_api { render json: @learning_path }
    end
  end

  # GET /learning_paths/new
  def new
    authorize LearningPath
    @learning_path = LearningPath.new
  end

  # GET /learning_paths/1/clone
  def clone
    authorize @learning_path
    @learning_path = @learning_path.duplicate
    render :new
  end

  # GET /learning_paths/1/edit
  def edit
    authorize @learning_path
  end

  # POST /learning_paths
  # POST /learning_paths.json
  def create
    authorize LearningPath
    @learning_path = LearningPath.new(learning_path_params)
    @learning_path.user = current_user

    respond_to do |format|
      if @learning_path.save
        @learning_path.create_activity :create, owner: current_user
        format.html { redirect_to @learning_path, notice: 'Learning path was successfully created.' }
        format.json { render :show, status: :created, location: @learning_path }
      else
        format.html { render :new }
        format.json { render json: @learning_path.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /learning_paths/1
  # PATCH/PUT /learning_paths/1.json
  def update
    authorize @learning_path
    respond_to do |format|
      if @learning_path.update(learning_path_params)
        @learning_path.create_activity(:update, owner: current_user) if @learning_path.log_update_activity?
        format.html { redirect_to @learning_path, notice: 'Learning path was successfully updated.' }
        format.json { render :show, status: :ok, location: @learning_path }
      else
        format.html { render :edit }
        format.json { render json: @learning_path.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /learning_paths/1
  # DELETE /learning_paths/1.json
  def destroy
    authorize @learning_path
    @learning_path.create_activity :destroy, owner: current_user
    @learning_path.destroy
    respond_to do |format|
      format.html { redirect_to learning_paths_url, notice: 'Learning path was successfully destroyed.' }
      format.json { head :no_content }
    end
  end


  private

  # Use callbacks to share common setup or constraints between actions.
  def set_learning_path
    @learning_path = LearningPath.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def learning_path_params
    params.require(:learning_path).permit(:id, :title, :description, :licence, :doi,
                                          :content_provider_id, :difficulty_level, :status,
                                          :prerequisites, :syllabus, :learning_objectives,
                                          { contributors: [] }, { authors: [] }, { target_audience: [] },
                                          { keywords: [] },
                                          { scientific_topic_names: [] }, { scientific_topic_uris: [] },
                                          { node_ids: [] }, { node_names: [] },
                                          { topic_links_attributes: [:id, :topic_id, :order, :_destroy] }, :public)
  end

end
