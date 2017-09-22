require_dependency 'issue'

module IssuePatch
	
    def self.included(base) # :nodoc:
        base.send(:extend, ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
            alias_method :reschedule_on_without_patch, :reschedule_on
			alias_method :reschedule_on, :reschedule_on_with_patch
			validates_presence_of :parent_issue_id, :if => :project_parent_issue_present
        end
    end

    module ClassMethods

    end

    module InstanceMethods
		include PlusganttUtilsHelper
		
		def project_parent_issue_present
			if Plusgantt.validate_parent_task
				issues_count = project.issues.count
				Rails.logger.info("project_parent_issue_present - count: " + issues_count.to_s)
				#Creating an issue
				if (issues_count > 0) && id.nil?
					Rails.logger.info("Creating an issue")
					return true
				end
				
				#Editing an issue
				if !id.nil?
					Rails.logger.info("Editing an issue")
					if @utils.nil?
						@utils = Utils.new()
					end
					parent_issue = @utils.get_issue_project_parent(project)
					if parent_issue.nil?
						return true
					else
						if id != parent_issue.id
							return true
						end
					end
				end
			end
			
			return false
		end
		
        def reschedule_on_with_patch(date)
			if Plusgantt.calculate_end_date && self.project.module_enabled?("plusgantt")
				Rails.logger.info("----------------reschedule_on_with_patch start----------------------------")
				Rails.logger.info("date: " + date.to_s)
				if @utils.nil?
					Rails.logger.info("----------------reschedule_on_with_patch initialize----------------------------")
					@utils = Utils.new()
				end
				@utils.get_hollidays_between(date, date, project)
				Rails.logger.info("issue: " + self.to_s)
				self.start_date = date
				if self.start_date && self.estimated_hours && self.leaf?
					@utils.update_issue_end_date(self)
				end
				Rails.logger.info("----------------reschedule_on_with_patch end----------------------------")
			else
				self.reschedule_on_without_patch(date)
			end
        end
      end
end

Rails.configuration.to_prepare do
    unless Issue.included_modules.include? Plusgantt
        Issue.send(:include, IssuePatch)
    end
end