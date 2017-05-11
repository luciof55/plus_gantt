require 'plusgantt/helpers/plusgantt'

module Plusgantt
	HOURS_BY_DAY = 8.0
	VALID_HOURS_BY_DAY = [4.0, 8.0, 12.0, 16.0]
	CALCULATE_END_DATE = false
	
	class << self
	
		def calculate_end_date
			if Setting.plugin_plus_gantt['calculate_end_date'].nil?
				CALCULATE_END_DATE
			else
				if Setting.plugin_plus_gantt['calculate_end_date'] == '1'
					true
				else
					false
				end
			end
		end
		
		def hour_by_day
			if Setting.plugin_plus_gantt['hour_by_day']
				by_settigns = Setting.plugin_plus_gantt['hour_by_day'].to_d
				if VALID_HOURS_BY_DAY.include?(by_settigns)
					by_settigns
				else
					HOURS_BY_DAY
				end
			else
				HOURS_BY_DAY
			end
		end
		
		def hollidays
			if Setting.plugin_plus_gantt['hollidays']
				Setting.plugin_plus_gantt['hollidays']
			else
				""
			end
		end
		
		def get_hollidays
			if Setting.plugin_plus_gantt['hollidays']
				Setting.plugin_plus_gantt['hollidays'].split(",").sort
			else
				[]
			end
		end
		
		def get_hollidays_js
			if Setting.plugin_plus_gantt['hollidays']
				Setting.plugin_plus_gantt['hollidays'].split(",").sort.to_json
			else
				[]
			end
		end
	end
end