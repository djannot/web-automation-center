class CloudsController < ApplicationController

  before_action :set_cloud, only: [:show, :edit, :update, :destroy]

  # Show the cloud APIs
  def index
    if current_user
      if Cloud.exists?(user_id: @current_user.id)
        @clouds = @current_user.clouds.all
      end
    else
        redirect_to :log_in
    end
  end

  # Show actions available for a specific cloud API
  def show
  end

  # Show the form to create a new cloud API
  def new
    @cloud = Cloud.new
  end

  # Show the form to modify an existing cloud API
  def edit
  end

  # Create a new cloud API
  def create
    @cloud = Cloud.new(cloud_params)
    current_user
    @cloud.user_id = current_user.id

    respond_to do |format|
      if @cloud.save
        format.html { redirect_to @cloud, notice: 'Cloud was successfully created.' }
        format.json { render action: 'show', status: :created, location: @cloud }
      else
        format.html { render action: 'new' }
        format.json { render json: @cloud.errors, status: :unprocessable_entity }
      end
    end
  end

  # Update an existing cloud API
  def update
    respond_to do |format|
      if @cloud.update(cloud_params)
        format.html { redirect_to @cloud, notice: 'Cloud was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @cloud.errors, status: :unprocessable_entity }
      end
    end
  end

  # Delete a cloud API
  def destroy
    @cloud.delete
    respond_to do |format|
      format.html { redirect_to clouds_url }
      format.json { head :no_content }
    end
  end

  # To return an error. Can be used by any controller
  def error
    @error = session[:error]
    session.delete(:error)
  end

  private
    # Set the current cloud API
    def set_cloud
      @cloud = Cloud.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def cloud_params
      params.require(:cloud).permit(:api, :url, :ip_addresses, :port, :token, :shared_secret, :bucket, :platform_id)
    end
end
