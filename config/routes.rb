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
match 'harvest_user' => 'harvest_entry#harvest_user', :as => :harvest_user
match 'harvest_settings' => 'harvest_entry#harvest_settings', :as => :harvest_settings
match 'harvest_settings_delete/:setting_id' => 'harvest_entry#harvest_settings', :via => :delete, :as => :harvest_settings_delete
match 'harvest_fetch' => 'harvest_entry#harvest_fetch', :as => :harvest_fetch
match 'harvest_fetch/day/today' => 'harvest_entry#harvest_fetch_day', :day => 'today', :via => :get, :as => :harvest_fetch_today
match 'harvest_fetch/day/:day' => 'harvest_entry#harvest_fetch_day', :day => /\d/, :via => :get, :as => :harvest_fetch_day
match 'harvest_fetch/week/:week' => 'harvest_entry#harvest_fetch_week', :week => 'current', :via => :get, :as => :harvest_fetch_week
match 'harvest_reconcile' => 'harvest_entry#reconcile', :as => :harvest_reconcile

match 'hatvest_sync' => 'harvest_entry#harvest_sync_status', :status => 'new', :via => :get, :as => :harvest_sync_status_new
match 'hatvest_sync/:status' => 'harvest_entry#harvest_sync_status', :status => /\/s/, :via => :get, :as => :harvest_sync_status
