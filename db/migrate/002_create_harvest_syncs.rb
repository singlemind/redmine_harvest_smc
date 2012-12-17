class CreateHarvestSyncs < ActiveRecord::Migration
  def change
    create_table :harvest_syncs do |t|
      t.integer :day_of_the_year
      t.integer :year
      t.datetime :created_at
      t.datetime :updated_at
      t.string :status
      t.string :matched_entries
      t.string :unmatched_entries
    end
    add_index :harvest_syncs, :day_of_the_year
    add_index :harvest_syncs, :year
    add_index :harvest_syncs, :status
  end
end
