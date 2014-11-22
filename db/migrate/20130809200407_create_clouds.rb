class CreateClouds < ActiveRecord::Migration
  def change
    create_table :clouds do |t|
    	t.string :api
      t.string :url
      t.string :ip_addresses
      t.integer :port
      t.string :token
      t.string :shared_secret
      t.string :bucket
      t.integer :user_id
      t.integer :platform_id

      t.timestamps
    end
  end
end
