class PgReport < ActiveRecord::Base
  unloadable
  belongs_to :project
  attr_accessible :id, :project_id, :control_date, :budget, :end_date, :progress, :expected_progress, :partial_budget, :hours_consumed, :hours_adjusted, :progress_status, :hours_status, :hours_percent_diff, :status
  
  validate :validate
  
  after_save :clearCache
  after_destroy :clearCache  
  
  def validate
    
  end
  
private
  def clearCache
    Rails.cache.clear
  end
end