# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

#rails 2.x routes:
#ActionController::Routing::Routes.draw do |map|
#        map.harvest 'harvest', :controller => 'harvest_entry', :action => 'index'
#        map.harvest_user 'harvest_user', :controller => 'harvest_entry', :action => 'harvest_user'
#end

#rails 3.x routes:
match 'harvest' => 'harvest_entry#index', :as => :harvest
match 'harvest/:status' => 'harvest_entry#index', :day => /\s/, :via => :get, :as => :harvest_status 
match 'harvest_reconcile' => 'harvest_entry#reconcile', :as => :harvest_reconcile
match 'harvest_user' => 'harvest_entry#harvest_user', :as => :harvest_user
match 'harvest_settings' => 'harvest_entry#harvest_settings', :as => :harvest_settings
match 'harvest_settings_delete/:setting_id' => 'harvest_entry#harvest_settings', :via => :delete, :as => :harvest_settings_delete
