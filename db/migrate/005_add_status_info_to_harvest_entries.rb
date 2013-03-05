class AddStatusInfoToHarvestEntries < ActiveRecord::Migration
  def change

    add_column :harvest_entries, :status_info, :string

  end
end
