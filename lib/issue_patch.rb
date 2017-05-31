require_dependency 'issue'

module IssuePatch
	
    def self.included(base) # :nodoc:
        base.send(:extend, ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
            alias_method :reschedule_on_without_patch, :reschedule_on
			alias_method :reschedule_on, :reschedule_on_with_patch
        end
    end

    module ClassMethods

    end

    module InstanceMethods
		include PlusganttUtilsHelper
		
        def reschedule_on_with_patch(date)
			if Plusgantt.calculate_end_date && self.project.module_enabled?("plusgantt")
				Rails.logger.info("----------------reschedule_on_with_patch start----------------------------")
				Rails.logger.info("date: " + date.to_s)
				if @utils.nil?
					Rails.logger.info("----------------reschedule_on_with_patch initialize----------------------------")
					@utils = Utils.new()
				end
				@utils.get_hollidays_between(date, date)
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