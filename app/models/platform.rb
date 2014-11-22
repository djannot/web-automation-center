class Platform < ActiveRecord::Base
	belongs_to :user
	has_many :clouds
	has_many :tasks
	attr_accessible :platform_type, :ip, :sys_admin, :sys_admin_password, :tenant_name, :tenant_admin, :tenant_admin_password
end
