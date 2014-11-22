class DemoController < ApplicationController
  include Favorites

	# Add a new task to a demo
  def add_task
  	@task = Task.new(params)
    current_user
    @task.user_id = current_user.id
  	@saved = false
    if @task.save
    	@saved = true
    end

    respond_to do |format|
    	format.js { render 'demo/execute_add_task' }
   	end
  end

	# Delete a task from a demo
  def delete_task
  	@task = Task.find(params[:id])
  	@task.destroy
  	@demo = Demo.find(@task.demo_id)

    respond_to do |format|
      format.js { render 'demo/delete_task' }
    end
  end

	# Re order a task in a demo before its previous task
  def up_task
  	@task = Task.find(params[:id])
  	@task.move_higher
  	@demo = Demo.find(@task.demo_id)

    respond_to do |format|
      format.js { render 'demo/up_or_down_task' }
    end
  end

	# Re order a task in a demo after its next task
  def down_task
  	@task = Task.find(params[:id])
  	@task.move_lower
  	@demo = Demo.find(@task.demo_id)

    respond_to do |format|
      format.js { render 'demo/up_or_down_task' }
    end
  end

	# Show more details about a task
  def show_task
  	@task = Task.find(params[:id])
  	@cloud = Cloud.find(@task.cloud_id) if @task.cloud_id
  	@platform = Platform.find(@task.platform_id) if @task.platform_id
  	@favorite = Favorite.find(@task.favorite_id)

    respond_to do |format|
      format.js { render 'demo/show_task' }
    end
  end

	# Execute an individual task
  def execute_task
  	@task = Task.find(params[:id])
  	@cloud = Cloud.find(@task.cloud_id) if @task.cloud_id
  	@platform = Platform.find(@task.platform_id) if @task.platform_id
  	@favorite = Favorite.find(@task.favorite_id)

    respond_to do |format|
      format.js { render 'demo/execute_task' }
    end
  end

	# Show the form to update the API associated to a task
  def update_api
  	@task = Task.find(params[:id])
  	current_user
  	@favorite = Favorite.find(@task.favorite_id)

    respond_to do |format|
      format.js { render 'demo/update_api' }
    end
  end

	# Update the API associated to a task
  def execute_update_api
		@task = Task.find(params[:id])
		@demo = Demo.find(@task.demo_id)
		if params[:all]
	  	@demo.tasks.each do |task|
				task.update_attribute(:cloud_id, params[:id_selected].to_i) if(params[:type] == "Cloud API" && params[:id_selected] != "")
				task.update_attribute(:platform_id, params[:id_selected].to_i) if(params[:type] == "Platform Management" && params[:id_selected] != "")
			end
		else
			@task.update_attribute(:cloud_id, params[:id_selected].to_i) if(params[:type] == "Cloud API" && params[:id_selected] != "")
			@task.update_attribute(:platform_id, params[:id_selected].to_i) if(params[:type] == "Platform Management" && params[:id_selected] != "")
		end

    respond_to do |format|
      format.js { render 'demo/execute_update_api' }
    end
  end

	# Show the form to add a regular expression to a task
  def add_regexpression
    @task = Task.find(params[:id])

    respond_to do |format|
      format.js { render 'demo/add_regexpression' }
    end
  end

	# Add a regular expression to a task
  def execute_add_regexpression
    @task = Task.find(params[:id])
    @regexpression = Regexpression.new(params)
    current_user
    @regexpression.user_id = current_user.id
    @regexpression.task_id = @task.id
    @regexpression.save
    @regexpressions = @task.regexpressions

    respond_to do |format|
      format.js { render 'demo/show_regexpressions' }
    end
  end

	# Delete a regular expression
  def delete_regexpression
    @regexpression = Regexpression.find(params[:id])
    @regexpression.delete

    respond_to do |format|
      format.js { render 'demo/delete_regexpression' }
    end
  end

	# Show all the regular expressions associated to a task
  def show_regexpressions
    @task = Task.find(params[:id])
    @regexpressions = @task.regexpressions

    respond_to do |format|
      format.js { render 'demo/show_regexpressions' }
    end
  end

	# Show the form to set the response codes expected for a task
  def show_response_codes
    @task = Task.find(params[:id])

    respond_to do |format|
      format.js { render 'demo/show_response_codes' }
    end
  end

	# Update the response codes expected for a task
  def execute_set_response_codes
    @task = Task.find(params[:id])
    @task.update_attribute(:response_codes, params[:response_codes])

    respond_to do |format|
      format.js { render 'demo/hide_response_codes' }
    end
  end

  private

    # Never trust parameters from the scary internet, only allow the white list through.
    def task_params
      params.require(:task).permit(:name, :description, :demo_id, :cloud_id, :platform_id, :favorite_id)
    end
end
