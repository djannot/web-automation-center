class CreatePlatforms < ActiveRecord::Migration
  def change
    create_table :platforms do |t|
    	t.string :platform_type
      t.string :ip
      t.string :sys_admin
      t.string :sys_admin_password
      t.string :tenant_name
      t.string :tenant_admin
      t.string :tenant_admin_password
      t.integer :user_id

      t.timestamps
    end
  end
end
