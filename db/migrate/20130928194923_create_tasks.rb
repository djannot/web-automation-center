class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
    	t.string :name
    	t.text :description
      t.integer :demo_id
    	t.integer :cloud_id
    	t.integer :platform_id
    	t.integer :favorite_id
    	t.integer :position
      t.integer :user_id
      t.string :response_codes

      t.timestamps
    end
  end
end
