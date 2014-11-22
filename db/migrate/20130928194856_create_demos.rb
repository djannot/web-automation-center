class CreateDemos < ActiveRecord::Migration
  def change
    create_table :demos do |t|
    	t.string :name
    	t.text :description
    	t.integer :user_id

      t.timestamps
    end
  end
end
