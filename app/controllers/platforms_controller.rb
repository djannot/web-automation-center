class PlatformsController < ApplicationController

  before_action :set_platform, only: [:show, :edit, :update, :destroy]

  # Show the platform APIs
  def index
    if current_user
      if Platform.exists?(user_id: @current_user.id)
        @platforms = @current_user.platforms.all
      end
    end
  end

  # Show actions available for a specific platform API
  def show
  end

  # Show the form to create a new platform API
  def new
    @platform = Platform.new
  end

  # Show the form to modify an existing platform API
  def edit
  end

  # Create a new platform API
  def create
    @platform = Platform.new(platform_params)
    current_user
    @platform.user_id = current_user.id

    respond_to do |format|
      if @platform.save
        format.html { redirect_to @platform, notice: 'Platform was successfully created.' }
        format.json { render action: 'show', status: :created, location: @platform }
      else
        format.html { render action: 'new' }
        format.json { render json: @platform.errors, status: :unprocessable_entity }
      end
    end
  end

  # Update an existing platform API
  def update
    respond_to do |format|
      if @platform.update(platform_params)
        format.html { redirect_to @platform, notice: 'Platform was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @platform.errors, status: :unprocessable_entity }
      end
    end
  end

  # Delete a platform API
  def destroy
    @platform.delete
    respond_to do |format|
      format.html { redirect_to platforms_url }
      format.json { head :no_content }
    end
  end

  private
    # Set the current platform API
    def set_platform
      @platform = Platform.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def platform_params
      params.require(:platform).permit(:platform_type, :ip, :sys_admin, :sys_admin_password, :tenant_name, :tenant_admin, :tenant_admin_password)
    end
end
