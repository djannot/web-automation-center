class Regexpression < ActiveRecord::Base
	belongs_to :task
	belongs_to :user
	attr_accessible :name, :expression, :description, :task_id, :user_id
end
