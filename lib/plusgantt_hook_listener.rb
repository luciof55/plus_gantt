class PlusganttHookListener < Redmine::Hook::ViewListener
	include PlusganttUtilsHelper
	
	render_on :view_issues_sidebar_issues_bottom, :partial => "plusgantt/issues_sidebar" 
   
	def controller_issues_new_after_save(context={})
		update_issue_end_date(context, true)
	end
   
	def controller_issues_edit_after_save(context={})
		update_issue_end_date(context, true)
	end
   
	def controller_issues_bulk_edit_before_save(context={})
		update_issue_end_date(context, false)
	end
   
	def update_issue_end_date(context={}, save)
		issue = context[:issue]
		if Plusgantt.calculate_end_date && issue.project.module_enabled?("plusgantt")
			@utils = Utils.new()
			if issue.start_date && issue.estimated_hours && issue.leaf?
				@utils.update_issue_end_date(issue)
				if save
					if issue.save
						Rails.logger.info("Issue updated: " + issue.id.to_s)
					else
						raise ActiveRecord::Rollback
					end
				end
			end
		end
	end
end