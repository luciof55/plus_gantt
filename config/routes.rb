# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

RedmineApp::Application.routes.draw do
	match '/issues/plusgantt/show(:id)', :to => 'plusgantt#show', via: [:get], :as => 'plusgantt_show'
	match '/projects/issues/plusgantt/(:id)', :to => 'plusgantt#show', via: [:get, :post], :as => 'project_plusgantt'
	match '/projects/issues/plusgantt_dashboard/show/(:id)', :to => 'plusgantt_dashboard#show', via: [:get, :post], :as => 'plusgantt_dashboard_show'
	match '/projects/issues/plusgantt_dashboard/show_calculate/(:id)', :to => 'plusgantt_dashboard#show_calculate', via: [:get, :post], :as => 'plusgantt_dashboard_show_calculate'
	match '/projects/issues/plusgantt_dashboard/init_run/(:id)', :to => 'plusgantt_dashboard#init_run', via: [:get, :post], :as => 'plusgantt_dashboard_init_run'
	match '/projects/issues/plusgantt_dashboard/run/(:id)', :to => 'plusgantt_dashboard#run', via: [:get, :post], :as => 'plusgantt_dashboard_run'
	match '/plusgantt_report/show', :to => 'plusgantt_report#show', via: [:get, :post], :as => 'plusgantt_report_show'
	match '/plusgantt_report/create', :to => 'plusgantt_report#create', via: [:get, :post], :as => 'plusgantt_report_create'
	match '/plusgantt_report/save', :to => 'plusgantt_report#save', via: [:get, :post], :as => 'plusgantt_report_save'
	match '/plusgantt_report/edit', :to => 'plusgantt_report#edit', via: [:get, :post], :as => 'plusgantt_report_edit'
	match '/plusgantt_report/detail', :to => 'plusgantt_report#detail', via: [:get, :post], :as => 'plusgantt_report_detail'
end