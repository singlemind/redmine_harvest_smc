class CreateHarvestEntries < ActiveRecord::Migration
  def change
    create_table :harvest_entries do |t|
      t.integer :harvest_id
      t.string :spent_at
      t.integer :user_id
      t.string :client
      t.integer :project_id
      t.string :project
      t.integer :task_id
      t.string :task
      t.float :hours
      t.float :hours_without_timer
      t.string :notes
      t.string :status
      t.datetime :created_at
      t.datetime :updated_at
      t.time :started_at
      t.time :ended_at
    end
    add_index :harvest_entries 
    add_index :harvest_id 
    add_index :status
  end
end
