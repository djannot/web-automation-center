class UsersController < ApplicationController
	skip_before_filter :require_login, :only => [:new, :create]

	# Show the form to sign up
	def new
	  @user = User.new
	end

	# Create the new user
	def create
	  @user = User.new(params[:user])
	  if @user.save
	    redirect_to root_url, :notice => "Signed up!"
	  else
	    render "new"
	  end
	end
end
