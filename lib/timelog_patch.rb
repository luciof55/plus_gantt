require_dependency 'time_entry'
require_dependency 'custom_field'

module TimelogPatch
	
    def self.included(base) # :nodoc:
        base.send(:extend, ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
			validate :validate_timelog
			def editable_by?(usr)
				#Rails.logger.info("------------------------editable_by inicio ------------------------")
				if self.spent_on >= Plusgantt.date_from_period_on && self.spent_on <= Plusgantt.date_to_period_on
					visible?(usr) && (
					  (usr == user && usr.allowed_to?(:edit_own_time_entries, project)) || usr.allowed_to?(:edit_time_entries, project)
					)
				else
					return false
				end
				#Rails.logger.info("------------------------editable_by fin ------------------------")
			end
        end
		
    end

    module ClassMethods

    end

    module InstanceMethods
		include PlusganttUtilsHelper
		
		def validate_timelog
			Rails.logger.info("------------------------validate_timelog inicio ------------------------")
			Rails.logger.info("------------------------self.spent_on: " + self.spent_on.to_s)
			if self.spent_on >= Plusgantt.date_from_period_on && self.spent_on <= Plusgantt.date_to_period_on
				if self.issue
					tracker_config = PgTrackerConfig.where(project: self.issue.project, tracker: self.issue.tracker).first
				end
				if tracker_config.nil? && self.issue
					tracker_config = PgTrackerConfig.where(tracker: self.issue.tracker).first
				end
				if tracker_config.nil? || tracker_config.allow_time_log == 1
					custom_field = CustomField.where("name = 'Extras'").first
					if custom_field
						self.custom_field_values.each do |item|
							if item.custom_field.id == custom_field.id
								if item.value == '0'
									Rails.logger.info("Validar horas")
									message = validate(self)
									if message != ''
										self.errors.add :hours, :invalid, message: message
									end
								else
									Rails.logger.info("No validar horas")
								end
								break
							end
						end
					end
				else
					self.errors.add :spent_on, :invalid, message: l(:tracker_allow_time_log_error)
				end
			else
				self.errors.add :spent_on, :invalid, message: l(:open_periodo_entry_error)
			end
			Rails.logger.info("------------------------validate_timelog fin ------------------------")
		end
		
		def validate(time_entry)
			first_day = Date.civil(time_entry.spent_on.year, time_entry.spent_on.month, 1)
			last_day  = (first_day >> 1) - 1
			new_time_entry_hours = time_entry.hours.to_i
			Rails.logger.info("------------------------validate_timelog es normal: " + new_time_entry_hours.to_s)
			place = get_place(time_entry.user)
			national_hollidays = []
			if place && time_entry.project.module_enabled?("redmine_workload")
				national_hollidays = WlNationalHoliday.where("? <= start_holliday AND start_holliday <= ? AND place = ?", first_day, last_day, place).order(start_holliday: :asc)
			end
			
			non_working_week_days = Setting['non_working_week_days']
			Rails.logger.info("------------------------non_working_week_days: " + non_working_week_days.to_s)
			workingHour = getWorkingHour(time_entry.user)
			
			timeSpan = first_day..last_day
			total_days = 0
			
			timeSpan.each do |day|
				cwday = day.cwday
				if cwday == 0
					#For Redmine Sunday is 7, no 0.
					cwday = 7
				end
				
				#Rails.logger.info("------------------------day: " + day.to_s + " --- cwday: " + cwday.to_s)
				if !non_working_week_days.include?(cwday.to_s) 
					total_days += getHolliday(national_hollidays, day)
				end
			end
			
			total_month_hour = total_days * workingHour
			
			Rails.logger.info("------------------------total_month_hour: " + total_month_hour.to_s)
			
			time_entries = TimeEntry.where('user_id = ? AND ? <= spent_on AND spent_on <= ?', time_entry.user.id, first_day, last_day)
			user_month_hour = 0
			time_entries.each do |time_entry_element|
				if !getTimeEntryExtra(time_entry_element) 
					if time_entry.id.nil?
						user_month_hour += time_entry_element.hours
					else
						if time_entry_element.id != time_entry.id
							user_month_hour += time_entry_element.hours
						end
					end
				end
			end
			
			Rails.logger.info("------------------------user_month_hour: " + user_month_hour.to_s)
			
			if (user_month_hour + new_time_entry_hours) > total_month_hour
				return l(:hour_time_entry_error, :user_month_hour => user_month_hour.to_s, :total_month_hour => total_month_hour.to_s)
			else
				return ''
			end
		 
		end
  
		def getTimeEntryExtra(time_entry)
			if @utils.nil?
				@utils = Utils.new()
			end
			return @utils.getTimeEntryExtra(time_entry)
		end
	
		def get_place(user)
			if @utils.nil?
				Rails.logger.info("----------------reschedule_on_with_patch initialize----------------------------")
				@utils = Utils.new()
			end
			return @utils.get_place(user)
		end
	
		def getWorkingHour(user)
			workingHour = 8.0
			if user && user.custom_value_for(CustomField.find_by_name_and_type('Jornada', 'UserCustomField')) &&
				user.custom_value_for(CustomField.find_by_name_and_type('Jornada', 'UserCustomField')).value && user.custom_value_for(CustomField.find_by_name_and_type('Jornada', 'UserCustomField')).value.to_i > 0
				workingHour = user.custom_value_for(CustomField.find_by_name_and_type('Jornada', 'UserCustomField')).value.to_i
				Rails.logger.info("------------------------workingHour: " + workingHour.to_s)
			end
			return workingHour.to_i
		end
		
		def getHolliday(national_hollidays, day)
			national_hollidays.each do |national_holliday|
				if national_holliday.start_holliday == day
					#Half day?
					if national_holliday.half_day && national_holliday.half_day == 1
						return 0.5
					else
						return 0
					end
				end
			end
			
			return 1
		end
	end
end

Rails.configuration.to_prepare do
	unless TimeEntry.included_modules.include? Plusgantt
		Rails.logger.info("Send TimelogPatch")
		TimeEntry.send(:include, TimelogPatch)
	end
end