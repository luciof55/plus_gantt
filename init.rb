require_dependency 'plusgantt_hook_listener'
require 'issue_patch'

Redmine::Plugin.register :plus_gantt do
  name 'Gantt Plus plugin'
  author 'Lucio Ferrero'
  description 'This is a plugin for Redmine wich render a project gantt adding a control date in order to visualize the expected ratio'
  version '0.0.3'
  url ''
  author_url 'https://www.linkedin.com/in/lucioferrero/'
  
  menu :project_menu, :plusgantt, {:controller => 'plusgantt', :action => 'show' }, :caption => :label_plusgantt, :after => :gantt, :param => :project_id
  
  project_module :plusgantt do
    permission :view_plusgantt, {:plusgantt => [:show]}
  end
  
  settings :default => {'empty' => true}, :partial => 'settings/plusgantt/general'
  
end

ActionDispatch::Callbacks.to_prepare do
  require 'plus_gantt'
end