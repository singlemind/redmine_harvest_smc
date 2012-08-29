# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

#get 'harvest', :to => 'harvest_entry#index'
#get 'harvest_user', :to => 'harvest_entry#harvest_user'

match 'harvest' => 'harvest_entry#index', :as => :harvest
match 'harvest_user' => 'harvest_entry#harvest_user', :as => :harvest_user
