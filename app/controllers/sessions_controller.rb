class SessionsController < ApplicationController
	skip_before_filter :require_login, :only => [:new, :create]

	# Show the login form
	def new
	end

	# Authenticate the user
	def create
	  user = User.authenticate(params[:email], params[:password])
	  if user
	    session[:user_id] = user.id
	    redirect_to root_url, :notice => "Logged in!"
	  else
	    flash.now.alert = "Invalid email or password"
	    render "new"
	  end
	end

	# Logout the user
	def destroy
	  session[:user_id] = nil
	  redirect_to root_url, :notice => "Logged out!"
	end
end
