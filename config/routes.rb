# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get '/projects/:project_id/issues/plusgantt', :to => 'plusgantt#show', :as => 'project_plusgantt'
get '/issues/plusgantt', :to => 'plusgantt#show'
get 'plusgantt', :to => 'plusgantt#show'

get '/projects/:project_id/issues/plusgantt_dashboard/show', :to => 'plusgantt_dashboard#show', :as => 'project_issues_date'
post '/projects/:project_id/issues/plusgantt_dashboard/calculate', :to => 'plusgantt_dashboard#calculate'