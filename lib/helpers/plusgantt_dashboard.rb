module PlusganttDashboardHelper
	
	class Dashboard
	
		include PlusganttUtilsHelper
		include Redmine::I18n
		include ERB::Util
	
		attr_reader  :control_date, :width_line, :therehold
		attr_accessor :error
		attr_accessor :utils
		attr_accessor :project
		attr_accessor :view
		
		# Relation types that are processed
		RELATIONS_TYPES = [IssueRelation::TYPE_BLOCKS, IssueRelation::TYPE_PRECEDES].freeze
		
		def initialize(options={})
			if @utils.nil?
				Rails.logger.info("----------------Dashboard initialize----------------------------")
				@utils = Utils.new()
			end
			if options[:control_date]
				@control_date = options[:control_date].to_date
			else
				@control_date = User.current.today
			end
			@threshold = 10
			@width_line = 340
		end
		
		def get_progress_text
			return get_progress_value.round(2).to_s + "%"
		end
		
		def get_expected_progress_text
			return get_expected_progress_value.round(2).to_s + "%"
		end
		
		def get_total_hours_text
			return get_estimated_hours_value.round(2).to_s + " hs"
		end
		
		def get_partial_budget_text
			return (get_progress_value * get_estimated_hours_value / 100).round(2).to_s + " hs"
		end
		
		def get_consumed_text
			return get_consumed_value.round(2).to_s + " hs"
		end
		
		def get_partial_budget_width
			return (get_progress_value * @width_line / 100).round(2)
		end
		
		def get_consumed_width
			return (get_consumed_value / get_estimated_hours_value * @width_line).round(2)
		end
		
		def get_consumed_class
			consumed = get_consumed_value
			partial_budget = get_progress_value * get_estimated_hours_value / 100
			if consumed <= partial_budget
				return "consumed_ok"
			else
				if ((consumed / partial_budget * 100).round(2) - 100) > @threshold
					return "consumed_red"
				else
					return "consumed_wargning"
				end
			end
		end
		
		def get_color_line
			progress = get_progress_value
			exp_progress = get_expected_progress_value
			if exp_progress <= progress
				return "#77933c"
			else
				if (exp_progress - progress).round(2) > @threshold
					return "#c0504d"
				else
					return "#cccc00"
				end
			end
		end
		
		def get_progress_value(project=nil)
			if project.nil?
				if @total_progress
					return @total_progress
				end
				project = @project
			end
			issues = project_issues(project)
			data = get_project_progress(issues)
			@total_progress = data[:total_progress]
			@estimated_hours = data[:estimated_hours]
			return @total_progress
		end
		
		def get_expected_progress_value(control_date=nil,project=nil)
			if control_date.nil?
				control_date = @control_date
			end
			if project.nil?
				project = @project
			end
			@expected_progress = @utils.calc_project_expected_progess(project, control_date)
			return @expected_progress
		end
		
		def get_estimated_hours_value(project=nil)
			if project.nil?
				if @estimated_hours
					return @estimated_hours
				end
				project = @project
			end
			issues = project_issues(project)
			data = get_project_progress(issues)
			@total_progress = data[:total_progress]
			@estimated_hours = data[:estimated_hours]
			return @estimated_hours
		end
		
		def get_consumed_value(project=nil)
			if project.nil?
				if @consumed_value
					return @consumed_value
				end
				project = @project
			end
			@consumed_value = @utils.get_project_total_spent_hours(project)
			return @consumed_value
		end
		
		def render_subprojects
			content = "".html_safe
			Project.project_tree(projects) do |subproject, level|
				s = view.link_to_project(subproject).html_safe
				content << " ".html_safe + s.html_safe
			end
			return content
		end
		
		def has_subprojects
			projects 
			if @projects && @projects.count > 0
				return true
			else
				return false
			end
		end
		
		def render_project_detail
			Rails.logger.info("----------------render_project_expected_progress----------------------------")
			content = "".html_safe
			if @project.module_enabled?("plusgantt")
				begin
					issues = project_issues(@project)
					label = view.content_tag(:span, get_project_detail(issues).html_safe).html_safe
					content << view.content_tag(:div, label, :class => "label").html_safe
				rescue => exception
					Rails.logger.info("Error: " + "#{exception.class}: #{exception.exception}")
				end
			else
				Rails.logger.info("Module not enabled")
			end
			return content
		end
		
		def recalculate_issue_end_date(issue, relations, predecessors)
			Rails.logger.info("----------------plus_gantt_recalculate_issue_end_date----------------------------")
			begin 
				calcualte_end_date(issue, relations, predecessors)
				@error = ""
				return {:processed => 0, :predecessors => predecessors}
			rescue => exception
				Rails.logger.info("Error: " + "#{exception.class}: #{exception.exception}")
				@error = l(:label_error_recalculate)
				return {:processed => -1, :predecessors => nil}
			end
			Rails.logger.info("----------------plus_gantt_recalculate_issue_end_date----------------------------")
		end
		
		def recalculate_predecessors_end_date(predecessors)
			Rails.logger.info("----------------recalculate_predecessors_end_date start----------------------------")
			begin
				predecessors.each do |key, value|
					end_date = nil
					value.each do |rel_issue|
						if end_date.nil?
							end_date = rel_issue.due_date
						else
							if rel_issue.due_date > end_date
								end_date = rel_issue.due_date
							end
						end
					end
					
					if !end_date.nil?
						key.start_date = (end_date + 1).to_date
						Rails.logger.info("Procesing follow or blocked: " + key.id.to_s + ' end_date: ' + key.start_date.to_s)
						#Calcualte end date
						begin
							update_issue_dates(key, true)
						rescue ActiveRecord::StaleObjectError
							key.reload
							Rails.logger.info("Already updated: " + key.id.to_s + ' end_date: ' + key.start_date.to_s)
						end
					end
				end
				return 0
			rescue => exception
				Rails.logger.info("Error: " + "#{exception.class}: #{exception.exception}")
				@error = l(:label_error_recalculate)
				return -1
			end
			Rails.logger.info("----------------recalculate_predecessors_end_date end----------------------------")
		end
		
		def validate_conf
			Rails.logger.info("----------------validate_conf----------------------------")
			if @project.module_enabled?("plusgantt")
				if Plusgantt.calculate_end_date
					return 0
				else
					Rails.logger.info("calculate_end_date is FALSE")
					@error = l(:label_calculate_issue_desactivated)
					return -2
				end
			else
				Rails.logger.info("Module not enabled")
				@error = l(:label_module_not_enabled)
				return -3
			end
			Rails.logger.info("----------------validate_conf----------------------------")
		end
		
		# Returns the issues that belong to +project+
		def project_issues(project)
			Rails.logger.info("----------------init get project_issues-----------------------------")
			Rails.logger.info("project_id: " + project.id.to_s)
			issues = Issue.visible.where("project_id = ?", project.id).to_a || []
			self.class.sort_issues!(issues)
			Rails.logger.info("----------------end get project_issues-----------------------------")
			return issues
		end
		
		# Returns a hash of the relations between the issues that are present on the project
		# and that should be processed, grouped by issue ids.
		def load_relations(issues)
			Rails.logger.info("----------------relations-----------------------------")
			if issues.count > 0
			  issue_ids = issues.map(&:id)
			  relations = IssueRelation.where(:issue_from_id => issue_ids, :issue_to_id => issue_ids, :relation_type => RELATIONS_TYPES).
				group_by(&:issue_to_id)
			else
			  relations = {}
			end
			return relations
		end
		
		# Return all the project nodes that will be displayed
		def projects
			return @projects if @projects
			@projects = Project.visible.where("parent_id = ?", @project.id).order("#{Project.table_name}.name ASC").to_a
			if @projects && @projects.count > 0
				@projects.each do |subproject|
					if !subproject.module_enabled?("plusgantt")
						@projects.delete(subproject)
					end
				end
			end
			return @projects
		end
		
		def create_reports_items(period)
			result = []
			projects = Project.visible.order("#{Project.table_name}.name ASC").to_a
			projects.each do |project|
				report_item = PgReport.new
				report_item.project = project
				report_item.control_date = period
				report_item.budget = get_estimated_hours_value(project)
				report_item.end_date = project.due_date
				report_item.progress = get_progress_value(project)
				report_item.expected_progress = get_expected_progress_value(period, project)
				report_item.partial_budget = (report_item.progress * report_item.budget / 100).round(2)
				report_item.hours_consumed = get_consumed_value(project)
				report_item.hours_adjusted = report_item.hours_consumed
				report_item.progress_status = (report_item.progress - report_item.expected_progress).round(2)
				report_item.hours_status = (report_item.partial_budget - report_item.hours_adjusted).round(2)
				if report_item.partial_budget > 0
					report_item.hours_percent_diff = ((report_item.partial_budget - report_item.hours_adjusted) / report_item.partial_budget).round(2)
				else
					report_item.hours_percent_diff = 0
				end
				report_item.status = 0
				result.push(report_item)
			end
			return result
		end
		
		private
		# Return progress & estimated hours
		def get_project_progress(issues)
			total_hours = 0.0
			total_done_ratio_hours = 0.0
			result = {}
			
			issues.each do |issue|
				if issue.leaf? && issue.estimated_hours
					total_done_ratio_hours += (issue.done_ratio * issue.estimated_hours)
					total_hours += issue.estimated_hours
				end
			end
			
			if total_hours > 0
				progress = (total_done_ratio_hours / total_hours).round(2)
				estimated_hours = total_hours.round(0)
				result = {:total_progress => progress, :estimated_hours  => estimated_hours}
			else
				result = {:total_progress => 0.0, :estimated_hours  => 0.0}
			end
			
			return result
		end
		
		# Return expected progress
		def get_project_detail(issues)
			datail = "".html_safe
			
			data = get_project_progress(issues)
			@total_progress = data[:total_progress]
			@estimated_hours = data[:estimated_hours]
			
			datail = l(:field_total_estimated_hours) + ": " + data[:estimated_hours].to_s + " h. " + l(:label_progress) + ": " + data[:total_progress].to_s + "%."
			
			return datail.html_safe
		end
		
		def calcualte_end_date(issue, relations, predecessors)
			if issue.leaf?
				Rails.logger.info("Leaf " + issue.id.to_s)
				rels = issue_relations(issue, relations)
				if rels.count > 0
					predecessors.store(issue, rels)
				else
					update_issue_dates(issue, true)
				end
			end
		end
		
		def update_issue_dates(issue, save)
			if issue.start_date && issue.estimated_hours && issue.leaf?
				@utils.update_issue_end_date(issue)
				if save
					if issue.save
						Rails.logger.info("Issue updated: " + issue.id.to_s)
					else
						Rails.logger.info("Issue error updated: " + issue.id.to_s)
						##raise ActiveRecord::Rollback
					end
				end
			else
				Rails.logger.info("Issue ignored: " + issue.id.to_s)
			end
		end
		
		def issue_relations(issue, relations)
			rels = []
			if relations && relations[issue.id]
				relations[issue.id].each do |relation|
					rels.push(relation.issue_from)
				end
			end
			return rels
		end
		
		def self.sort_issues!(issues)
			issues.sort! {|a, b| sort_issue_logic(a) <=> sort_issue_logic(b)}
		end

		def self.sort_issue_logic(issue)
			julian_date = Date.new()
			ancesters_start_date = []
			current_issue = issue
			begin
			  ancesters_start_date.unshift([current_issue.start_date || julian_date, current_issue.id])
			  current_issue = current_issue.parent
			end while (current_issue)
			ancesters_start_date
		end
		
	end
end
