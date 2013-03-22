class AddIsAdminToHarvestUsers < ActiveRecord::Migration
  def change

   add_column :harvest_users, :is_harvest_admin, :boolean

  end
end
