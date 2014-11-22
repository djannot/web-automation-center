class DemosController < ApplicationController
  include Favorites

	before_action :set_demo, only: [:show, :edit, :update, :destroy]

	# Show the demos
	def index
    if current_user
      if Demo.exists?(user_id: @current_user.id)
        @demos = @current_user.demos.all
      end
    end
  end

	# Show the form to create a new demo
  def new
    @demo = Demo.new
  end

	# Create a new demo
  def create
    @demo = Demo.new(demo_params)
    current_user
    @demo.user_id = @current_user.id

    respond_to do |format|
      if @demo.save
        format.html { redirect_to @demo, notice: 'Demo was successfully created.' }
        format.json { render action: 'show', status: :created, location: @demo }
      else
        format.html { render action: 'new' }
        format.json { render json: @demo.errors, status: :unprocessable_entity }
      end
    end
  end

	# Update a demo
  def update
    respond_to do |format|
      if @demo.update(demo_params)
        format.html { redirect_to @demo, notice: 'Demo was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @demo.errors, status: :unprocessable_entity }
      end
    end
  end

	# Delete a demo
  def destroy
    @demo.destroy
    respond_to do |format|
      format.html { redirect_to demos_url }
      format.json { head :no_content }
    end
  end

  private
		# Set the current demo
  	def set_demo
      @demo = Demo.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def demo_params
      params.require(:demo).permit(:name, :description)
    end
end
