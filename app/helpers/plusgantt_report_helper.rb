module PlusganttReportHelper
  
  def render_action_links
    links = []
    if User.current.allowed_to_globally?(:plusgantt_report)
      links << link_to(l(:label_show_report), :controller => 'plusgantt_report', :action => "show")
    end
    if User.current.allowed_to_globally?(:plusgantt_report_manage)
      links << link_to(l(:label_create_report), :controller => 'plusgantt_report', :action => "create")
    end
    links.join(" | ").html_safe
  end
  
end