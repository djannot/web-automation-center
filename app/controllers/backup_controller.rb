class BackupController < ApplicationController
	def index
	end

	# Backup user data either to a file or to the cloud
	def backup
		data = ""
		current_user
		if params["favorites"]
			data << "favorite_relations = Hash.new\n"
			if params[:demo_id]
				@favorites = []
				Task.where(["demo_id = ?", params[:demo_id]]).each do |task|
					@favorites << task.favorite
				end
			elsif params[:favorite_id]
				@favorites = Favorite.where(["id = ?", params[:favorite_id]])
			else
				@favorites = @current_user.favorites.all
			end
			@favorites.each do |favorite|
				favorite_id = favorite.attributes["id"]
				favorite_attributes = favorite.attributes
				favorite_attributes.delete("id")
				favorite_attributes.delete("user_id")
				favorite_attributes.delete("created_at")
				favorite_attributes.delete("updated_at")
				data << "favorite = @current_user.favorites.create(#{favorite_attributes})\n"
				data << "favorite_relations[#{favorite_id}] = favorite.id\n"
			end
		end

		if params["demos"]
			data << "demo_relations = Hash.new\n"
			params[:demo_id] ? @demos = Demo.where(["id = ?", params[:demo_id]]) : @demos = @current_user.demos.all
			@demos.each do |demo|
				demo_id = demo.attributes["id"]
				demo_attributes = demo.attributes
				demo_attributes.delete("id")
				demo_attributes.delete("user_id")
				demo_attributes.delete("created_at")
				demo_attributes.delete("updated_at")
				data << "demo = @current_user.demos.create(#{demo_attributes})\n"
				data << "demo_relations[#{demo_id}] = demo.id\n"
			end
		end

		if params["platforms"]
			data << "platform_relations = Hash.new\n"
			@platforms = @current_user.platforms.all
			@platforms.each do |platform|
				platform_id = platform.attributes["id"]
				platform_attributes = platform.attributes
				platform_attributes.delete("id")
				platform_attributes.delete("user_id")
				platform_attributes.delete("created_at")
				platform_attributes.delete("updated_at")
				data << "platform = @current_user.platforms.create(#{platform_attributes})\n"
				data << "platform_relations[#{platform_id}] = platform.id\n"
			end
		end

		if params["clouds"]
			data << "cloud_relations = Hash.new\n"
			@clouds = @current_user.clouds.all
			@clouds.each do |cloud|
				cloud_id = cloud.attributes["id"]
				platform_id = cloud.attributes["platform_id"] if params["platforms"]
				cloud_attributes = cloud.attributes
				cloud_attributes.delete("id")
				cloud_attributes.delete("user_id")
				cloud_attributes.delete("platform_id")
				cloud_attributes.delete("created_at")
				cloud_attributes.delete("updated_at")
				if(platform_id)
					data << "cloud = @current_user.clouds.create(#{cloud_attributes}.merge!({'platform_id' => platform_relations[#{platform_id}]}))\n"
				else
					data << "cloud = @current_user.clouds.create(#{cloud_attributes})\n"
				end
				data << "cloud_relations[#{cloud_id}] = cloud.id\n"
			end
		end

		if params["demos"]
			data << "task_relations = Hash.new\n"
			params[:demo_id] ? @tasks = Task.where(["demo_id = ?", params[:demo_id]]) : @tasks = @current_user.tasks.all
			@tasks.each do |task|
				task_id = task.attributes["id"]
				demo_id = task.attributes["demo_id"]
				cloud_id = task.attributes["cloud_id"] if params["clouds"]
				platform_id = task.attributes["platform_id"] if params["platforms"]
				favorite_id = task.attributes["favorite_id"]
				task_attributes = task.attributes
				task_attributes.delete("id")
				task_attributes.delete("user_id")
				task_attributes.delete("demo_id")
				task_attributes.delete("cloud_id")
				task_attributes.delete("platform_id")
				task_attributes.delete("favorite_id")
				task_attributes.delete("created_at")
				task_attributes.delete("updated_at")
				if platform_id
					data << "task = @current_user.tasks.create(#{task_attributes}.merge!({'demo_id' => demo_relations[#{demo_id}], 'platform_id' => platform_relations[#{platform_id}],'favorite_id' => favorite_relations[#{favorite_id}]}))\n"
				elsif cloud_id
					data << "task = @current_user.tasks.create(#{task_attributes}.merge!({'demo_id' => demo_relations[#{demo_id}], 'cloud_id' => cloud_relations[#{cloud_id}],'favorite_id' => favorite_relations[#{favorite_id}]}))\n"
				else
					data << "task = @current_user.tasks.create(#{task_attributes}.merge!({'demo_id' => demo_relations[#{demo_id}],'favorite_id' => favorite_relations[#{favorite_id}]}))\n"
				end
				data << "task_relations[#{task_id}] = task.id\n"
			end
		end

		if params["demos"]
			data << "regexpression_relations = Hash.new\n"
			if params[:demo_id]
				@regexpressions = []
				@tasks.each do |task|
					task.regexpressions.each do |regexpression|
						@regexpressions << regexpression
					end
				end
			else
				@regexpressions = @current_user.regexpressions.all
			end
			@regexpressions.each do |regexpression|
				regexpression_id = regexpression.attributes["id"]
				task_id = regexpression.attributes["task_id"]
				regexpression_attributes = regexpression.attributes
				regexpression_attributes.delete("id")
				regexpression_attributes.delete("user_id")
				regexpression_attributes.delete("task_id")
				regexpression_attributes.delete("created_at")
				regexpression_attributes.delete("updated_at")
				data << "regexpression = @current_user.regexpressions.create(#{regexpression_attributes}.merge!({'task_id' => task_relations[#{task_id}]}))\n"
				data << "regexpression_relations[#{regexpression_id}] = regexpression.id\n"
			end
		end

		if params[:encrypt_password]
			data = data.encrypt(:symmetric, :algorithm => 'des-ecb', :password => params[:encrypt_password])
		end

		if params[:cloud]
			@response, @headers, @url = amazon_request("Put", "/#{current_user.email}/Backup-#{Time.now.to_formatted_s(:number)}", "", data, :cloud => @s3)
			redirect_to :action => "list_cloud_data"
		elsif params[:backup_action] == "share_favorite"
			@response, @headers, @url = amazon_request("Put", "/Favorites/#{@favorites[0].api_type}/#{@favorites[0].api}/#{current_user.email}/#{@favorites[0].description}", "", data, :cloud => @s3)
			logger.info @response.body
			respond_to do |format|
				format.js { render "shared/execute_share_favorite" }
			end
		elsif params[:backup_action] == "share_demo"
			@response, @headers, @url = amazon_request("Put", "/Demos/#{current_user.email}/#{@demos[0].name}", "", data, :cloud => @s3)
			logger.info @response.body
			respond_to do |format|
				format.js { render "shared/execute_share_demo" }
			end
		else
			send_data(data, :filename => "Backup-#{Time.now.to_formatted_s(:number)}.txt" )
		end
	end

	# Show backup, favorite items and demo items stored in the cloud
	def list_cloud_data
		begin
			@response, @headers, @url = amazon_request("Get", "/?prefix=#{current_user.email}&amp;delimiter=%2F", "", "", :cloud => @s3)
			@response_favorites, @headers_favorites, @url_favorites = amazon_request("Get", "/?prefix=Favorites&amp;delimiter=%2F", "", "", :cloud => @s3)
			@response_demos, @headers_demos, @url_demos  = amazon_request("Get", "/?prefix=Demos&amp;delimiter=%2F", "", "", :cloud => @s3)
		rescue
			session[:error] = "Can't connect to the Amazon bucket. Check the environment variables"
			redirect_to :controller => "clouds", :action => "error", :id => "0"
		end
	end

	# Restore user data either from a file or from the cloud
	def restore
		begin
			current_user
			if params[:file]
				file_content = params[:file].read.to_s
				data = file_content.decrypt(:symmetric, :algorithm => 'des-ecb', :password => params[:password])
				eval(data)
			elsif params[:api_type]
				@response, @headers, @url = amazon_request("Get", "/Favorites/" + params[:api_type] + "/" + params[:api] + "/" + params[:email] + "/" + params[:name], "", "", :cloud => @s3)
				eval(@response.body)
			elsif params[:name]
				@response, @headers, @url = amazon_request("Get", "/Demos/" + params[:email] + "/" + params[:name], "", "", :cloud => @s3)
				eval(@response.body)
			else
				@response, @headers, @url = amazon_request("Get", "/" + params[:email] + "/" + params[:key], "", "", :cloud => @s3)
				data = @response.body.decrypt(:symmetric, :algorithm => 'des-ecb', :password => params[:password])
				eval(data)
			end
		rescue
			begin
				puts file_content
				eval(file_content)
			rescue Exception => e
				@exception = e
			end
		end
	end

	# Delete all the current user data
	def delete
		current_user
		current_user.regexpressions.destroy_all
		current_user.tasks.destroy_all
		current_user.clouds.destroy_all
		current_user.platforms.destroy_all
		current_user.demos.destroy_all
		current_user.favorites.destroy_all
	end

	# Delete backup, favorite items or demo items stored in the cloud
	def delete_cloud_data
		current_user
		if params[:api_type]
			if current_user.email == params[:email]
				@response, @headers, @url = amazon_request("Delete", "/Favorites/" + params[:api_type] + "/" + params[:api] + "/" + params[:email] + "/" + params[:name], "", "", :cloud => @s3)
			end
		elsif params[:name]
			if current_user.email == params[:email]
				@response, @headers, @url = amazon_request("Delete", "/Demos/" + params[:email] + "/" + params[:name], "", "", :cloud => @s3)
			end
		else
			@response, @headers, @url = amazon_request("Delete", "/" + params[:email] + "/" + params[:key], "", "", :cloud => @s3)
		end
		redirect_to :action => "list_cloud_data"
	end
end
