class CreateHarvestUsers < ActiveRecord::Migration
  def change
    create_table :harvest_users do |t|
      t.integer :redmine_user_id
      t.integer :harvest_user_id
      t.datetime :created_at
      t.datetime :updated_at
      t.binary :harvest_username_crypt
      t.binary :harvest_password_crypt
    end
    add_index :harvest_users, :redmine_user_id
  end
end
