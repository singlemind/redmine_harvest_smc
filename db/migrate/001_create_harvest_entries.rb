class CreateHarvestEntries < ActiveRecord::Migration
  def change
    create_table :harvest_entries do |t|
      t.integer :redmine_user_id
      t.string :redmine_name
      t.integer :redmine_time_entry_id
      t.integer :redmine_issue_id
      t.integer :harvest_id
      #this should probably be a .datetime
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
    add_index :harvest_entries, :harvest_id 
    add_index :harvest_entries, :status
    add_index :harvest_entries, :redmine_user_id
    add_index :harvest_entries, :redmine_issue_id

  end
end
