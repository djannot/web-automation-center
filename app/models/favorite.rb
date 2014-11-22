class Favorite < ActiveRecord::Base
	belongs_to :user
	has_one :task
	attr_accessible :description, :http_method, :path_or_url, :headers, :body, :api, :api_type, :privilege
end
