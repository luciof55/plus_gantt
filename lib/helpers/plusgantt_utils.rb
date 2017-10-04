module PlusganttUtilsHelper
	class Utils

		def initialize()
		end
		
		def get_hollidays_between(earlier_date, later_date, project, place)
			hollidays = 0
			#Rails.logger.info("get_hollidays_between: " + Plusgantt.get_hollidays.to_s)
			if project.module_enabled?("redmine_workload")
				#Rails.logger.info("----------------get_hollidays_between: Using redmine_workload----------------------------")
				if place
					national_hollidays = WlNationalHoliday.where("? <= start_holliday AND start_holliday <= ? AND place = ?", earlier_date, later_date, place)
					hollidays = national_hollidays.count{|v| (![0,6].include?(v.start_holliday.to_date.wday))}
				end
			else
				if Plusgantt.get_hollidays
					hollidays = Plusgantt.get_hollidays.count{|d| (earlier_date <= d.to_date && d.to_date <= later_date && ![0,6].include?(d.to_date.wday))}
				end
			end
			return hollidays
		end
		
		def update_issue_vacations_start_date(issue)
			#Rails.logger.info("update_issue_vacations_start_date: " + Plusgantt.get_hollidays.to_s)
			if issue.assigned_to && issue.project.module_enabled?("redmine_workload")
				#Rails.logger.info("----------------update_issue_vacations_start_date: Using redmine_workload----------------------------")
				user = issue.assigned_to.id
				day = issue.start_date
				vacation = WlUserVacation.where("user_id = ? AND date_from <= ? AND date_to >= ?", user, day, day)
				if !vacation.empty? then
					issue.start_date = vacation[0].date_to + 1
					cal_start_date(issue)
				end
			end
		end
		
		def update_issue_vacations_end_date(issue)
			Rails.logger.info("----------------update_issue_vacations_end_date start----------------------------")
			if issue.assigned_to && issue.project.module_enabled?("redmine_workload")
				user = issue.assigned_to.id
				vacations = WlUserVacation.where("user_id = ? AND date_from <= ? AND date_from > ?", user, issue.due_date, issue.start_date)
				vacations.sort_by {|v| v[:date_to]}
				if !vacations.empty? then
					aux_days_left = 0
					vacations.each do |vacation|
						Rails.logger.info("Vacation found: " + vacation.date_to.to_s)
						aux_end_date = [vacation.date_to, issue.due_date].min
						vacation_days = vacation.date_from..aux_end_date
						aux_days_left += vacation_days.count{|d| (![0,6].include?(d.to_date.wday))}
					end
					Rails.logger.info("aux_days_left: " + aux_days_left.to_s)
					if aux_days_left > 0
						aux_end_date = issue.due_date + 1
						aux_days_left = aux_days_left - 1
						while aux_days_left > 0 do
							if ![0,6].include?(aux_end_date.wday) && !DateTools::IsVacation(aux_end_date, user) && !DateTools.IsHoliday(aux_end_date)
								aux_days_left = aux_days_left - 1
							end
							aux_end_date = aux_end_date + 1
						end
						issue.due_date = aux_end_date
						Rails.logger.info("new issue.due_date: " + aux_end_date.to_s)
					end
				end
			end
			Rails.logger.info("----------------update_issue_vacations_end_date end----------------------------")
		end
		
		#Return how many working days are between two date, ignoring hollidays
		def calc_days_between_date(earlier_date, later_date)
			days_diff = (later_date - earlier_date).to_i
			weekdays = 0
			if days_diff >= 7
			  whole_weeks = (days_diff/7).to_i
			  later_date -= whole_weeks*7  
			  weekdays += whole_weeks*5
			end
			if later_date >= earlier_date
			  dates_between = earlier_date..(later_date)
			  weekdays += dates_between.count{|d| ![0,6].include?(d.wday)}
			end
			return weekdays
		end
		
		def calc_weekenddays_between_date(earlier_date, later_date)
			Rails.logger.info("----------------calc_weekenddays_between_date start----------------------------")
			days_diff = (later_date - earlier_date).to_i
			weekenddays = 0
			if days_diff >= 7
			  whole_weeks = (days_diff/7).to_i
			  Rails.logger.info("whole_weeks: " + whole_weeks.to_s)
			  later_date -= whole_weeks*7
			  Rails.logger.info("new later_date: " + later_date.to_s)
			  weekenddays += whole_weeks*2
			  Rails.logger.info("3 - weekenddays: " + weekenddays.to_s)
			end
			if later_date >= earlier_date
			  dates_between = earlier_date..(later_date)
			  weekenddays += dates_between.count{|d| ![1,2,3,4,5].include?(d.wday)}
			  Rails.logger.info("4 - weekenddays: " + weekenddays.to_s)
			end
			Rails.logger.info("5 - weekenddays: " + weekenddays.to_s)
			return weekenddays
			Rails.logger.info("----------------calc_weekenddays_between_date end----------------------------")
		end
	
		def get_asignacion(issue)
			if issue.custom_value_for(CustomField.find_by_name_and_type('asignacion', 'IssueCustomField')) &&
				issue.custom_value_for(CustomField.find_by_name_and_type('asignacion', 'IssueCustomField')).value.to_d > 0
				return issue.custom_value_for(CustomField.find_by_name_and_type('asignacion', 'IssueCustomField')).value.to_d
			end
			
			if issue.assigned_to && issue.assigned_to.custom_value_for(CustomField.find_by_name_and_type('asignacion', 'UserCustomField')) &&
				issue.assigned_to.custom_value_for(CustomField.find_by_name_and_type('asignacion', 'UserCustomField')).value.to_d > 0
				return issue.assigned_to.custom_value_for(CustomField.find_by_name_and_type('asignacion', 'UserCustomField')).value.to_d
			end
			
			if issue.project.custom_value_for(CustomField.find_by_name_and_type('asignacion', 'ProjectCustomField')) &&
				issue.project.custom_value_for(CustomField.find_by_name_and_type('asignacion', 'ProjectCustomField')).value.to_d > 0
				return issue.project.custom_value_for(CustomField.find_by_name_and_type('asignacion', 'ProjectCustomField')).value.to_d
			end
			
			return Plusgantt.hour_by_day
		end
	
		def update_issue_end_date(issue)
			#Validate start_date	
			cal_start_date(issue)
			Rails.logger.info("----------------update_issue_end_date----------------------------")
			Rails.logger.info("start date modified to: " + issue.start_date.to_s)
			Rails.logger.info("----------------update_issue_end_date----------------------------")
			
			#calculate end date.
			hour_by_day = get_asignacion(issue)
			days = (issue.estimated_hours / hour_by_day).ceil
			
			if days <= 1 
				issue.due_date = issue.start_date
			else
				issue.due_date = issue.start_date + days.to_i - 1
				Rails.logger.info("----------------update_issue_end_date----------------------------")
				Rails.logger.info("days: " + days.to_s)
				Rails.logger.info("----------------update_issue_end_date----------------------------")
				issue.due_date = cal_end_date(issue.start_date, issue.due_date, issue)
			end
			
			update_issue_vacations_end_date(issue)
			
		end
		
		def cal_start_date(issue)
			start_date = issue.start_date
			project = issue.project
			if start_date.wday == 6
				start_date = (start_date + 2).to_date
			else 
				if start_date.wday == 0
					start_date = (start_date + 1).to_date
				end
			end
			
			hollidays = get_hollidays_between(start_date, start_date, project, get_place(issue.assigned_to))
			if hollidays.to_i > 0
				issue.start_date = (start_date + hollidays).to_date
				cal_start_date(issue)
			else
				issue.start_date = start_date.to_date
				update_issue_vacations_start_date(issue)
			end
		end
	   
		def cal_end_date(start_date, end_date, issue)
			project = issue.project
			Rails.logger.info("----------------cal_end_date start----------------------------")
			Rails.logger.info("start_date: " + start_date.to_s)
			Rails.logger.info("end_date: " + end_date.to_s)
			weekenddays = calc_weekenddays_between_date(start_date, end_date)
			if weekenddays == 0
				Rails.logger.info("1 - weekenddays: " + weekenddays.to_s)
				hollidays = get_hollidays_between(start_date, end_date, project, get_place(issue.assigned_to))
				#Rails.logger.info("Hollydays: " + hollidays.to_s)
				if hollidays.to_i > 0
					start_date = (end_date + 1).to_date
					end_date = (end_date + hollidays.to_i).to_date
					weekenddays = calc_weekenddays_between_date(start_date, end_date)
					if weekenddays == 0
						hollidays = get_hollidays_between(end_date, end_date, project, get_place(issue.assigned_to))
						#Rails.logger.info("Hollydays: " + hollidays.to_s)
						if hollidays.to_i > 0
							end_date = (end_date + hollidays.to_i).to_date
							return cal_end_date(end_date, end_date, issue)
						else
							return end_date.to_date
						end
					else
						if end_date.wday == 6
							Rails.logger.info("DIA SABADO")
							return cal_end_date((end_date + 2).to_date, (end_date + 2 + (weekenddays - 1)).to_date, issue)
						else
							if end_date.wday == 0
								Rails.logger.info("DIA DOMINGO")
								return cal_end_date((end_date + 1).to_date, (end_date + 1 + (weekenddays - 1)).to_date, issue)
							else
								Rails.logger.info("DIA:" + end_date.wday.to_s)
								return cal_end_date(end_date, (end_date + weekenddays).to_date, issue)
							end
						end
					end
				end;
				return end_date.to_date
			else
				hollidays = get_hollidays_between(start_date, end_date, project, get_place(issue.assigned_to))
				#Rails.logger.info("Hollydays: " + hollidays.to_s)
				if hollidays.to_i > 0
					weekenddays += calc_weekenddays_between_date( (end_date + 1).to_date, (end_date + hollidays.to_i).to_date)
					end_date = (end_date + hollidays.to_i).to_date
				end
				if end_date.wday == 6
					Rails.logger.info("DIA SABADO")
					return cal_end_date((end_date + 2).to_date, (end_date + 2 + (weekenddays - 1)).to_date, issue)
				else
					if end_date.wday == 0
						Rails.logger.info("DIA DOMINGO")
						return cal_end_date((end_date + 1).to_date, (end_date + 1 + (weekenddays - 1)).to_date, issue)
					else
						Rails.logger.info("DIA:" + end_date.wday.to_s)
						return cal_end_date(end_date, (end_date + weekenddays).to_date, issue)
					end
				end
			end
			Rails.logger.info("----------------cal_end_date end----------------------------")
		end
	
		def calc_issue_expected_progress(issue, control_date)
			if issue.start_date && control_date >= issue.start_date
				if issue.due_before
					if control_date >= issue.due_before
						return 100.0
					else
						total_hours = 0.0
						if issue.leaf?
							return calc_task_expected_progress(issue, control_date)
						else
							issue.descendants.each do |child_issue|
								#Rails.logger.info("Issue Padre: " + issue.to_s + ". Issue hijo: " + child_issue.to_s)
								if !child_issue.estimated_hours.nil? 
									total_hours += (calc_task_expected_progress(child_issue, control_date) / 100.0) * child_issue.estimated_hours.to_d
									#Rails.logger.info("Acumulando las horas del hijo según avance: " + total_hours.to_s)	
								end
							end
							
							if issue.estimated_hours && issue.estimated_hours.to_d > 0
								total_hours += (calc_task_expected_progress(issue, control_date) / 100.0) * issue.estimated_hours.to_d
								#Rails.logger.info("Acumulando las horas propias del issue según avance: " + total_hours.to_s)
							end
							
							if issue.total_estimated_hours && issue.total_estimated_hours.to_d > 0
								estimated_progress = ( (total_hours / issue.total_estimated_hours.to_d ) * 100.0).round(2)
								if estimated_progress > 100.0
									estimated_progress = 100.0
								end
							else
								estimated_progress = 0.0
							end
							
							return estimated_progress
						end
					end
				else
					return 0.0
				end
			else
				return 0.0
			end
		end
 
		def calc_task_expected_progress(issue, control_date)
			if issue.start_date && control_date >= issue.start_date
				if issue.due_before
					if control_date >= issue.due_before
						return 100.0
					else
						if issue.estimated_hours && issue.estimated_hours.to_i > 0
							if issue.assigned_to && issue.project.module_enabled?("redmine_workload")
								timeSpan = issue.start_date..control_date
								days = DateTools::getRealDistanceInDays(timeSpan, issue.assigned_to.id)
							else
								days = calc_days_between_date(issue.start_date, control_date)
								hollidays = get_hollidays_between(issue.start_date, control_date, issue.project, issue.assigned_to)
								#Rails.logger.info("Hollydays: " + hollidays.to_s)
								days -= hollidays.to_i
							end
							
							hour_by_day = get_asignacion(issue)
							total_hours = hour_by_day * days
						
							if total_hours >= issue.estimated_hours.to_i
								return 100.0
							else
								return ( ( total_hours / issue.estimated_hours.to_i ) * 100.0).round(2)
							end
						else
							return 100.0
						end
					end
				else
					return 0.0
				end
			else
				return 0.0
			end
		end
	  
		def calc_version_expected_progress(version, control_date, issues)
			if version.start_date && control_date >= version.start_date
				if version.due_date
					if control_date >= version.due_date
						return 100.0
					else
						total_hours = 0.0
						total_estimated_hours = 0.0
						issues.each do |issue|
							if !issue.estimated_hours.nil? 
								total_hours += (calc_task_expected_progress(issue, control_date) / 100.0) * issue.estimated_hours.to_d
								total_estimated_hours += issue.estimated_hours.to_d
							end
						end
						if total_estimated_hours.to_d > 0
							estimated_progress = ( (total_hours / total_estimated_hours.to_d ) * 100.0).round(2)
							if estimated_progress > 100.0
								estimated_progress = 100.0
							end
						else
							estimated_progress = 0.0
						end
						return estimated_progress
					end
				else
					return 0.0
				end
			else
				return 0.0
			end
		end
	
		def calc_project_expected_progess(project, control_date)
			#Get project's parent issue  
			issues = Issue.visible.where("project_id = ? and issues.parent_id is null", project.id).to_a || []
			if issues && issues.size == 1
				return calc_issue_expected_progress(issues[0], control_date)
			else
				#If there is cero o two o more parent issues, no expected progress is calculated
				return 0.0
			end
		end
		
		def get_project_total_hours(project)
			issue = get_issue_project_parent(project)
			if !issue.nil?
				return issue.total_estimated_hours.round(2)
			else
				#If theres is cero o two o more parent issues, no expected progress is calculated
				return 0.0
			end
		end
		
		def get_project_total_spent_hours(project)
			issue = get_issue_project_parent(project)
			if !issue.nil?
				return issue.total_spent_hours.round(2)
			else
				#If theres is no parent issue, no expected progress is calculated
				return 0.0
			end
		end
		
		def get_issue_project_parent(project)
			#Get project's parent issue
			issues = Issue.visible.where("project_id = ? and issues.parent_id is null", project.id).to_a || []
			if issues && issues.size == 1
				return issues[0]
			else
				return
			end
		end
		
		def get_place(user)
			place = nil
			if user && user.custom_value_for(CustomField.find_by_name_and_type('Sede', 'UserCustomField')) &&
				user.custom_value_for(CustomField.find_by_name_and_type('Sede', 'UserCustomField')).value
				index = user.custom_value_for(CustomField.find_by_name_and_type('Sede', 'UserCustomField')).value.to_s.index('-')
				if !index.nil? && index > 0 && user.custom_value_for(CustomField.find_by_name_and_type('Sede', 'UserCustomField')).value.to_s[0, index].to_i > 0
					place = user.custom_value_for(CustomField.find_by_name_and_type('Sede', 'UserCustomField')).value.to_s[0, index].to_i
					Rails.logger.info("------------------------Utils Sede: " + place.to_s)
				end
			end
			return place
		end
	end
end