# The controller for actions related to the Package model
class PackagesController < ApplicationController
  before_action :set_package, only: [:show, :edit, :update, :destroy]
  before_action :set_breadcrumbs

  include SearchableIndex

  # GET /packages
  # GET /packages.json
  def index
  end

  # GET /packages/1
  # GET /packages/1.json
  def show
    authorize @package
  end

  # GET /packages/new
  def new
    authorize Package
    @package = Package.new
  end

  # GET /packages/1/edit
  def edit
    authorize @package
  end

  # POST /packages
  # POST /packages.json
  def create
    authorize Package
    @package = Package.new(package_params)
    @package.user = current_user

    respond_to do |format|
      if @package.save
        @package.create_activity :create, owner: current_user
        current_user.packages << @package
        format.html { redirect_to @package, notice: 'Package was successfully created.' }
        format.json { render :show, status: :created, location: @package }
      else
        format.html { render :new }
        format.json { render json: @package.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /packages/1
  # PATCH/PUT /packages/1.json
  def update
    authorize @package
    respond_to do |format|
      if @package.update(package_params)
        @package.create_activity(:update, owner: current_user) if @package.log_update_activity?
        format.html { redirect_to @package, notice: 'Package was successfully updated.' }
        format.json { render :show, status: :ok, location: @package }
      else
        format.html { render :edit }
        format.json { render json: @package.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /packages/1
  # DELETE /packages/1.json
  def destroy
    authorize @package
    @package.create_activity :destroy, owner: current_user
    @package.destroy
    respond_to do |format|
      format.html { redirect_to packages_url, notice: 'Package was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
    def set_package
      @package = Package.friendly.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def package_params
      params.require(:package).permit(:title, :description, :image, :image_url, :public, {:keywords => []}, {:material_ids => []}, {:event_ids => []})
    end
end
