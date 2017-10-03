module PlusganttReportHelper
  
  def render_action_links
    links = []
    links << link_to(l(:label_show_report), :controller => 'plusgantt_report', :action => "show")
	links << link_to(l(:label_create_report), :controller => 'plusgantt_report', :action => "create")   	
    links.join(" | ").html_safe
  end
  
end