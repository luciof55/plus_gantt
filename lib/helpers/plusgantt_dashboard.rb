module PlusganttDashboardHelper
	
	class Dashboard
	
		include PlusganttUtilsHelper
		include Redmine::I18n
		include ERB::Util
	
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
			if project.module_enabled?("plusgantt")
				begin
					issues = project_issues(project)
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
		
		def recalculate_issue_end_date
			Rails.logger.info("----------------plus_gantt_recalculate_issue_end_date----------------------------")
			if project.module_enabled?("plusgantt")
				if Plusgantt.calculate_end_date
					Rails.logger.info("calculate_end_date is TRUE")
					issues = project_issues(project)
					relations = load_relations(issues)
					begin
						issues_updated = calcualte_end_date(issues, relations)
						@error = ""
						return issues_updated
					rescue => exception
						Rails.logger.info("Error: " + "#{exception.class}: #{exception.exception}")
						@error = l(:label_error_recalculate)
						return -1
					end
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
			Rails.logger.info("----------------plus_gantt_recalculate_issue_end_date----------------------------")
		end
		
		private
		
		# Return expected progress
		def get_project_detail(issues)
			datail = "".html_safe
			progress = "0".html_safe
			estimated_hours = "0".html_safe
			
			total_hours = 0.0
			total_done_ratio_hours = 0.0
			
			issues.each do |issue|
				if !issue.parent_id && issue.total_estimated_hours
					total_done_ratio_hours += (issue.done_ratio * issue.total_estimated_hours)
					total_hours += issue.total_estimated_hours
				end
			end
			
			if total_hours > 0
				progress = (total_done_ratio_hours / total_hours).round(2).to_s
				estimated_hours = total_hours.to_s
			end
			
			datail = l(:field_total_estimated_hours) + ": " + estimated_hours + " h. " + l(:label_progress) + ": " + progress + "%."
			
			return datail.html_safe
		end
		
		# Return all the project nodes that will be displayed
		def projects
			return @projects if @projects
			
			@projects = Project.visible.where("parent_id = ?", project.id).order("#{Project.table_name}.name ASC").to_a
			
			if @projects && @projects.count > 0
				@projects.each do |subproject|
					if !subproject.module_enabled?("plusgantt")
						@projects.delete(subproject)
					end
				end
			end
			
			return @projects
        
		end
		
		def calcualte_end_date(issues, relations)
			self.class.sort_issues!(issues)
			predecessors = Hash.new []
			issued_update = 0
			issues.each do |issue|
				if issue.leaf?
					Rails.logger.info("Leaf " + issue.id.to_s)
					rels = issue_relations(issue, relations)
					if rels.count > 0
						predecessors.store(issue, rels)
					else
						#Calcualte end date
						issued_update+= 1
						update_issue_dates(issue, true)
					end
				end
			end
			
			predecessors.each do |key, value|
				end_date = nil
				value.each do |rel_issue|
					if end_date.nil?
						end_date = rel_issue.due_before
					else
						if rel_issue.due_before > end_date
							end_date = rel_issue.due_before
						end
					end
				end
				
				if !end_date.nil?
					key.start_date = (end_date + 1).to_date
					Rails.logger.info("Procesing follow or blocked: " + key.id.to_s + ' end_date: ' + key.start_date.to_s)
					#Calcualte end date
					issued_update+= 1
					update_issue_dates(key, true)
				end
			end
			
			return issued_update
		end
		
		def update_issue_dates(issue, save)
			if issue.start_date && issue.estimated_hours && issue.leaf?
				@utils.update_issue_end_date(issue)
				if save
					if issue.save
						Rails.logger.info("Issue updated: " + issue.id.to_s)
					else
						raise ActiveRecord::Rollback
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
		
		# Returns the issues that belong to +project+
		def project_issues(project)
			Issue.visible.where("project_id = ?", project.id).to_a || []
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
