class CreateFavorites < ActiveRecord::Migration
  def change
    create_table :favorites do |t|
    	t.text :description
      t.string :http_method
      t.string :path_or_url
      t.text :headers
      t.text :body
      t.string :api
      t.string :api_type
      t.string :privilege
      t.integer :user_id
      t.timestamps
    end
  end
end
