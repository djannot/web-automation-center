class Cloud < ActiveRecord::Base
	belongs_to :user
	belongs_to :platform
	has_many :tasks
	attr_accessible :api, :url, :ip_addresses, :port, :token, :shared_secret, :bucket, :platform_id
end