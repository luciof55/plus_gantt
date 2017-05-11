require_dependency 'issue'

module IssuePatch
	
    def self.included(base) # :nodoc:
        base.send(:extend, ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
            alias_method :reschedule_on, :reschedule_on_with_patch
        end
    end

    module ClassMethods

    end

    module InstanceMethods
		include Plusgantt
		
        def reschedule_on_with_patch(date)
			Rails.logger.info("----------------reschedule_on_with_patch start----------------------------")
			if Plusgantt.calculate_end_date
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
			else
				self.reschedule_on(date)
			end
			Rails.logger.info("----------------reschedule_on_with_patch end----------------------------")
        end
      end
end

Rails.configuration.to_prepare do
    #unless Issue.included_modules.include? IssuePatch
        Issue.send(:include, IssuePatch)
    #end
end