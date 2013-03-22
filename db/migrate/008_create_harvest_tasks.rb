class CreateHarvestTasks < ActiveRecord::Migration
  def change
    create_table :harvest_tasks do |t|
      t.integer :task_id
      t.string :task_name
      t.boolean :task_deactivated
      t.integer :task_project_id
    end

    add_index :harvest_tasks, :task_name
    add_index :harvest_tasks, :task_project_id
    
  end
end
