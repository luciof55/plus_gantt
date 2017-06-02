module PlusganttUtilsHelper
	class Utils

		def initialize()
		end
		
		def get_hollidays_between(earlier_date, later_date)
			hollidays = 0
			Rails.logger.info("get_hollidays_between: " + Plusgantt.get_hollidays.to_s)
			if Plusgantt.get_hollidays
				hollidays += Plusgantt.get_hollidays.count{|d| (earlier_date <= d.to_date && d.to_date <= later_date)}
			end
			return hollidays
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
			issue.start_date = cal_start_date(issue.start_date)
			Rails.logger.info("----------------update_issue_end_date----------------------------")
			Rails.logger.info("start date modified to: " + issue.start_date.to_s)
			Rails.logger.info("----------------update_issue_end_date----------------------------")
			
			#calculate end date.
			hour_by_day = get_asignacion(issue)
			days = (issue.estimated_hours / hour_by_day).ceil
			
			if days <= 1 
				issue.due_date = issue.start_date
			else
				end_date = issue.start_date + days.to_i - 1
				Rails.logger.info("----------------update_issue_end_date----------------------------")
				Rails.logger.info("days: " + days.to_s)
				Rails.logger.info("----------------update_issue_end_date----------------------------")
				issue.due_date = cal_end_date(issue.start_date, end_date)
			end
		end
		
		def cal_start_date(start_date)
			if start_date.wday == 6
				start_date = (start_date + 2).to_date
			else 
				if start_date.wday == 0
					start_date = (start_date + 1).to_date
				end
			end
			
			hollidays = get_hollidays_between(start_date, start_date)
			if hollidays.to_i > 0
				return cal_start_date((start_date + hollidays).to_date)
			else
				return start_date.to_date
			end
		end
	   
		def cal_end_date(start_date, end_date)
			Rails.logger.info("----------------cal_end_date start----------------------------")
			Rails.logger.info("start_date: " + start_date.to_s)
			Rails.logger.info("end_date: " + end_date.to_s)
			weekenddays = calc_weekenddays_between_date(start_date, end_date)
			if weekenddays == 0
				Rails.logger.info("1 - weekenddays: " + weekenddays.to_s)
				hollidays = get_hollidays_between(start_date, end_date)
				Rails.logger.info("Hollydays: " + hollidays.to_s)
				if hollidays.to_i > 0
					start_date = (end_date + 1).to_date
					end_date = (end_date + hollidays.to_i).to_date
					weekenddays = calc_weekenddays_between_date(start_date, end_date)
					if weekenddays == 0
						hollidays = get_hollidays_between(end_date, end_date)
						Rails.logger.info("Hollydays: " + hollidays.to_s)
						if hollidays.to_i > 0
							end_date = (end_date + hollidays.to_i).to_date
							return cal_end_date(end_date, end_date)
						else
							return end_date.to_date
						end
					else
						if end_date.wday == 6
							Rails.logger.info("DIA SABADO")
							return cal_end_date((end_date + 2).to_date, (end_date + 2 + (weekenddays - 1)).to_date)
						else
							if end_date.wday == 0
								Rails.logger.info("DIA DOMINGO")
								return cal_end_date((end_date + 1).to_date, (end_date + 1 + (weekenddays - 1)).to_date)
							else
								Rails.logger.info("DIA:" + end_date.wday.to_s)
								return cal_end_date(end_date, (end_date + weekenddays).to_date)
							end
						end
					end
				end;
				return end_date.to_date
			else
				hollidays = get_hollidays_between(start_date, end_date)
				Rails.logger.info("Hollydays: " + hollidays.to_s)
				if hollidays.to_i > 0
					weekenddays += calc_weekenddays_between_date( (end_date + 1).to_date, (end_date + hollidays.to_i).to_date)
					end_date = (end_date + hollidays.to_i).to_date
				end
				if end_date.wday == 6
					Rails.logger.info("DIA SABADO")
					return cal_end_date((end_date + 2).to_date, (end_date + 2 + (weekenddays - 1)).to_date)
				else
					if end_date.wday == 0
						Rails.logger.info("DIA DOMINGO")
						return cal_end_date((end_date + 1).to_date, (end_date + 1 + (weekenddays - 1)).to_date)
					else
						Rails.logger.info("DIA:" + end_date.wday.to_s)
						return cal_end_date(end_date, (end_date + weekenddays).to_date)
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
								Rails.logger.info("Issue Padre: " + issue.to_s + ". Issue hijo: " + child_issue.to_s)
								if !child_issue.estimated_hours.nil? 
									total_hours += (calc_task_expected_progress(child_issue, control_date) / 100.0) * child_issue.estimated_hours.to_d
									Rails.logger.info("Acumulando las horas del hijo según avance: " + total_hours.to_s)	
								end
							end
							
							if issue.estimated_hours && issue.estimated_hours.to_d > 0
								total_hours += (calc_task_expected_progress(issue, control_date) / 100.0) * issue.estimated_hours.to_d
								Rails.logger.info("Acumulando las horas propias del issue según avance: " + total_hours.to_s)
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
						days = calc_days_between_date(issue.start_date, control_date)
						hollidays = get_hollidays_between(issue.start_date, control_date)
						Rails.logger.info("Hollydays: " + hollidays.to_s)
						days -= hollidays.to_i
						
						hour_by_day = get_asignacion(issue)
						total_hours = hour_by_day * days
						
						if issue.estimated_hours && issue.estimated_hours.to_i > 0
							if total_hours > issue.estimated_hours.to_i
								return 100.0
							else
								return ( ( total_hours / issue.estimated_hours.to_i ) * 100.0).round(2)
							end
						else
							return 0.0
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
	
		def calc_project_expected_progess(project)
		end
	end
end