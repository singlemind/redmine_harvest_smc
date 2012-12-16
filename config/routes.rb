# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

#rails 3.x routes:
#match 'harvest' => 'harvest_entry#index', :as => :harvest
#match 'harvest_user' => 'harvest_entry#harvest_user', :as => :harvest_user

#rails 2.x routes:
ActionController::Routing::Routes.draw do |map|
        map.harvest 'harvest', :controller => 'harvest_entry', :action => 'index'
        map.harvest_user 'harvest_user', :controller => 'harvest_entry', :action => 'harvest_user'
end
