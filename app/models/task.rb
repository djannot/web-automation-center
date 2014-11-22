class Task < ActiveRecord::Base
	belongs_to :demo
	acts_as_list scope: :demo
	belongs_to :favorite
	belongs_to :cloud
	belongs_to :platform
	belongs_to :user
	has_many :regexpressions, dependent: :destroy
	attr_accessible :name, :description, :response_codes, :demo_id, :cloud_id, :platform_id, :favorite_id, :user_id
end
