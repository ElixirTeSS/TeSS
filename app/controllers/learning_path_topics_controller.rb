class LearningPathTopicsController < ApplicationController
  before_action -> { feature_enabled?('learning_paths') }
  before_action :set_topic, only: %i[show edit update destroy]
  before_action :set_breadcrumbs

  include SearchableIndex

  def index
    respond_to do |format|
      format.html
      format.json
      format.json_api { render({ json: @learning_path_topics }.merge(api_collection_properties)) }
    end
  end

  def show
    respond_to do |format|
      format.html
      # format.json
      # format.json_api { render json: @learning_path_topic }
    end
  end

  # GET /topics/new
  def new
    authorize LearningPathTopic
    @learning_path_topic = LearningPathTopic.new
  end

  def edit
    authorize @learning_path_topic
  end

  def create
    authorize LearningPathTopic
    @learning_path_topic = LearningPathTopic.new(topic_params)
    @learning_path_topic.user = current_user

    respond_to do |format|
      if @learning_path_topic.save
        @learning_path_topic.create_activity :create, owner: current_user
        format.html { redirect_to @learning_path_topic, notice: 'Topic was successfully created.' }
        # format.json { render :show, status: :created, location: @learning_path_topic }
      else
        format.html { render :new }
        # format.json { render json: @learning_path_topic.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @learning_path_topic
    respond_to do |format|
      if @learning_path_topic.update(topic_params)
        @learning_path_topic.create_activity(:update, owner: current_user) if @learning_path_topic.log_update_activity?
        format.html { redirect_to @learning_path_topic, notice: 'Topic was successfully updated.' }
        # format.json { render :show, status: :ok, location: @learning_path_topic }
      else
        format.html { render :edit }
        # format.json { render json: @learning_path_topic.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @learning_path_topic
    @learning_path_topic.create_activity :destroy, owner: current_user
    @learning_path_topic.destroy
    respond_to do |format|
      format.html { redirect_to learning_path_topics_url, notice: 'Topic was successfully destroyed.' }
      # format.json { head :no_content }
    end
  end

  private

  def set_topic
    @learning_path_topic = LearningPathTopic.find(params[:id])
  end

  def topic_params
    params.require(:learning_path_topic).permit(
      :title, :description, :difficulty_level, { keywords:  [] }, { material_ids: [] }, { event_ids: [] },
      { items_attributes: [:id, :resource_type, :resource_id, :order, :comment, :_destroy] })
  end

  def add_base_breadcrumbs(_)
    super('learning_paths')
    add_index_breadcrumb(controller_name, 'Topics')
  end
end
