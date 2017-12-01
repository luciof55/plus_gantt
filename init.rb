require 'helpers/plusgantt_utils'
require 'helpers/plusgantt_dashboard'
require 'helpers/plusgantt_chart'
require 'issue_patch'
require 'timelog_patch'
require_dependency 'plusgantt_hook_listener'

ActionDispatch::Callbacks.to_prepare do
  require 'plus_gantt'
end

Redmine::Plugin.register :plus_gantt do
  name 'Gantt Plus plugin'
  author 'Lucio Ferrero'
  description 'This is a plugin for Redmine wich render a project gantt adding a control date in order to visualize the expected ratio'
  version '0.0.7'
  url 'https://github.com/luciof55/plus_gantt'
  author_url 'https://www.linkedin.com/in/lucioferrero/'
  
  menu :top_menu, :plusgantt_report, { :controller => 'plusgantt_report', :action => 'show' }, :caption => :label_plusgantt, :if =>  Proc.new { User.current.logged? }
  
  menu :project_menu, :plusgantt_dashboard, {:controller => 'plusgantt_dashboard', :action => 'show' }, :caption => :label_plusgantt, :after => :gantt, :param => :project_id
  
  project_module :plusgantt do
    permission :view_plusgantt, {:plusgantt => [:show]}
	permission :plusgantt_dashboard, {:plusgantt_dashboard => [:show, :show_calculate, :init_run, :run]}
	permission :plusgantt_report, {:plusgantt_report => [:show, :detail]}
	permission :plusgantt_report_manage, {:plusgantt_report => [:show, :create, :save, :edit, :detail]}
	permission :config_tracker_timelog, {:pg_tracker_config => [:edit, :update, :create, :destroy, :new]}
  end
  
  settings :default => {'empty' => true}, :partial => 'settings/plusgantt/general'
  
end


