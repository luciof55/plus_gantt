class PlusganttHookListener < Redmine::Hook::ViewListener
	include PlusganttUtilsHelper
	
	render_on :view_issues_sidebar_issues_bottom, :partial => "plusgantt/issues_sidebar" 
	
	render_on :view_projects_show_right, :partial => "plusgantt/project_show_right"
	
	def controller_issues_new_after_save(context={})
		update_issue_end_date(context, true)
	end
   
	def controller_issues_edit_after_save(context={})
		update_issue_end_date(context, true)
	end
   
	def controller_issues_bulk_edit_before_save(context={})
		update_issue_end_date(context, false)
	end
	
	# def controller_timelog_edit_before_save(context={})
		# Rails.logger.info("controller_timelog_edit_before_save params: " + context[:params].to_s)
		# custom_field = CustomField.where("name = 'Extras'").first
		# if custom_field && context[:params]
			# aux_params = context[:params][:time_entry]
			# if aux_params && aux_params[:custom_field_values]
				# context[:time_entry].custom_field_values.each do |item|
					# if item.custom_field.id == custom_field.id
						# aux_params = aux_params[:custom_field_values]
						# Rails.logger.info("custom_field.id.to_s: " + custom_field.id.to_s)
						# Rails.logger.info("aux_params[custom_field.id]: " + aux_params[custom_field.id.to_s])
						# if aux_params[custom_field.id.to_s] == '0'
							# Rails.logger.info("Seteando 0")
							# item.value = '0'
						# else
							# Rails.logger.info("Seteando 1")
							# item.value = '1'
						# end
						# break
					# end
				# end
			# end
		# end
	# end
   
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