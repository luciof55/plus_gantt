# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get '/projects/:project_id/issues/plusgantt', :to => 'plusgantt#show', :as => 'project_plusgantt'
get '/issues/plusgantt', :to => 'plusgantt#show'
get 'plusgantt', :to => 'plusgantt#show'