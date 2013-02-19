class CreateHarvestSettings < ActiveRecord::Migration
  def change
    create_table :harvest_settings do |t|
      t.string :notes_string
      t.integer :redmine_issue
      t.integer :redmine_user_id
      t.integer :harvest_user_id
      t.string :status
      t.datetime :created_at
      t.datetime :updated_at
    end
    add_index :harvest_settings, :redmine_user_id
    add_index :harvest_settings, :notes_string

  end
end
