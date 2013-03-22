class CreateHarvestProjects < ActiveRecord::Migration
  def change
    create_table :harvest_projects do |t|
      t.integer :project_id
      t.string :project_name
      t.boolean :project_active
      t.integer :project_client_id
      t.string :project_code
      t.string :project_notes
    end

    add_index :harvest_projects, :project_name
    add_index :harvest_projects, :project_code
  end
end
