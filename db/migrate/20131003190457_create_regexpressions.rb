class CreateRegexpressions < ActiveRecord::Migration
  def change
    create_table :regexpressions do |t|
    	t.string :name
    	t.string :expression
    	t.text :description
      t.integer :task_id
      t.integer :user_id

      t.timestamps
    end
  end
end
