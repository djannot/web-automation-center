class Demo < ActiveRecord::Base
	has_many :tasks, -> {order(:position)}, dependent: :destroy
	belongs_to :user
	attr_accessible :name, :description
end
