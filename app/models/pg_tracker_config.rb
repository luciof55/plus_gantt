class PgTrackerConfig < ActiveRecord::Base
  unloadable
  belongs_to :tracker
  belongs_to :project
  attr_accessible :id, :tracker_id, :project_id, :allow_time_log
  
  validates_presence_of :tracker_id, :allow_time_log
  
  validate :validate
  
  after_save :clearCache
  after_destroy :clearCache  
  
  def validate
    if self.id && self.project_id
		if PgTrackerConfig.where("id != ? AND project_id = ? AND tracker_id = ?", self.id, self.project_id, self.tracker_id).count > 0
			errors.add :project_id, :tracker_config_duplicated_error 
		end
	else
		if self.id && PgTrackerConfig.where("id != ? AND tracker_id = ?", self.id, self.tracker_id).count > 0
			errors.add :tracker_id, :tracker_config_duplicated_error 
		end
	end
	
	if self.id.nil?
		if self.project_id
			if PgTrackerConfig.where("project_id = ? AND tracker_id = ?", self.project_id, self.tracker_id).count > 0
				errors.add :project_id, :tracker_config_duplicated_error 
			end
		else
			if PgTrackerConfig.where("tracker_id = ? and project_id is null", self.tracker_id).count > 0
				errors.add :tracker_id, :tracker_config_duplicated_error 
			end
		end
	end
	
  end
  
private
  def clearCache
    Rails.cache.clear
  end
end