class PgReport < ActiveRecord::Base
  unloadable
  belongs_to :project
  attr_accessible :id, :project_id, :control_date, :budget, :end_date, :progress, :expected_progress, :partial_budget, :hours_consumed, :hours_adjusted, :progress_status, :hours_status, :hours_percent_diff, :status

  validate :validate

  after_save :clearCache
  after_destroy :clearCache

  def partial_budget=(partial_budget)
    if hours_adjusted
      hours_status = (partial_budget - hours_adjusted).round(2)
      write_attribute(:hours_status, hours_status)
    end

    if partial_budget > 0 && hours_adjusted
      hours_percent_diff = ((partial_budget - hours_adjusted) / partial_budget * 100).round(2)
      write_attribute(:hours_percent_diff, hours_percent_diff)
    else
      write_attribute(:hours_percent_diff, 0)
    end

    write_attribute(:partial_budget, partial_budget)
  end

  def hours_adjusted=(hours_adjusted)
    if partial_budget
      hours_status = (partial_budget - hours_adjusted).round(2)
      write_attribute(:hours_status, hours_status)
    end

    if partial_budget && partial_budget > 0 && hours_adjusted
      hours_percent_diff = ((partial_budget - hours_adjusted) / partial_budget * 100).round(2)
      write_attribute(:hours_percent_diff, hours_percent_diff)
    else
      write_attribute(:hours_percent_diff, 0)
    end

    write_attribute(:hours_adjusted, hours_adjusted)
  end

  def status_class
    case status
      when 1
        'consumed_ok'
      when 0
        'consumed_warning'
      else
        'consumed_red'
    end
  end

  def item_progress_status_class
    if progress_status >= 0
      'consumed_ok'
    else
      if progress_status * -1 > Plusgantt.progress_status_threshold
        'consumed_red'
      else
        'consumed_warning'
      end
    end
  end

  def item_consumed_class
    self.class.get_consumed_class(hours_consumed, partial_budget)
  end

  def self.get_consumed_class(consumed, partial_budget)
    if consumed <= partial_budget
      'consumed_ok'
    else
      if ((consumed / partial_budget * 100).round(2) - 100) > Plusgantt.progress_status_threshold
        'consumed_red'
      else
        'consumed_warning'
      end
    end
  end

  def item_color_line
    return self.class.get_color_line(progress, expected_progress)
  end

  def self.get_color_line(progress, exp_progress)
    if exp_progress <= progress
      '#77933c'
    else
      if (exp_progress - progress).round(2) > Plusgantt.progress_status_threshold
        '#c0504d'
      else
        '#cccc00'
      end
    end
  end

  def validate
    
  end
  
private
  def clearCache
    Rails.cache.clear
  end
end