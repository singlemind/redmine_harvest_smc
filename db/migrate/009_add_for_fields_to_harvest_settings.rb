class AddForFieldsToHarvestSettings < ActiveRecord::Migration
  def change

    add_column :harvest_settings, :for_fields, :string
    add_index :harvest_settings, :for_fields

  end
end
