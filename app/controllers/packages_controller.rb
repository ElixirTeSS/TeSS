class PackagesController < ApplicationController
  before_action :set_package, only: [:show, :edit, :update, :destroy]

  require 'bread_crumbs'

  before_action :set_search_params, :only => :index
  before_action :set_facet_params, :only => :index

  # Should allow token authentication for API calls
  acts_as_token_authentication_handler_for User, except: [:index, :show, :check_title] #only: [:new, :create, :edit, :update, :destroy]

  # User auth should be required in the web interface as well; it's here rather than in routes so that it
  # doesn't override the token auth, above.
  before_filter :authenticate_user!, except: [:index, :show, :check_title]

  # Should prevent forgery errors for JSON posts.
  skip_before_filter :verify_authenticity_token, :if => Proc.new { |c| c.request.format == 'application/json' }

  include TeSS::BreadCrumbs

  @@facet_fields = %w( owner )


  # GET /packages
  # GET /packages.json
  def index
    @facet_fields = @@facet_fields
    @packages = solr_search(Package, @search_params, @@facet_fields, @facet_params)
  end

  # GET /packages/1
  # GET /packages/1.json
  def show
  end

  # GET /packages/new
  def new
    @package = Package.new
  end

  # GET /packages/1/edit
  def edit
  end

  # POST /packages
  # POST /packages.json
  def create
    @package = Package.new(package_params)

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
    respond_to do |format|
      if @package.update(package_params)
        @package.create_activity :update, owner: current_user
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
    @package.destroy
    respond_to do |format|
      format.html { redirect_to packages_url, notice: 'Package was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_package
      @package = Package.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def package_params
      params.require(:package).permit(:name, :description, :image_url, :public)
    end


    def set_search_params
      params.permit(:q)
      @search_params = params[:q] || ''
    end

    def set_facet_params
      params.permit(@@facet_fields)
      @facet_params = {}
      @@facet_fields.each {|facet_title| @facet_params[facet_title] = params[facet_title] if !params[facet_title].nil? }
    end


end
