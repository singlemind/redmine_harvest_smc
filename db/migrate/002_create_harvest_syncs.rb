class CreateHarvestSyncs < ActiveRecord::Migration
  def change
    create_table :harvest_syncs do |t|
      t.integer :day_of_the_year
      t.integer :year
      t.datetime :created_at
      t.datetime :updated_at
      t.string :status
      t.integer :for_redmine_user_id

    end
    add_index :harvest_syncs, :day_of_the_year
    add_index :harvest_syncs, :year
    add_index :harvest_syncs, :status
    add_index :harvest_syncs, :for_redmine_user_id

  end
end
