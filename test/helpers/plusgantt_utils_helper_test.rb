require File.expand_path('../../test_helper', __FILE__)

class PlusganttUtilsHelperTest < ActionView::TestCase
  include PlusganttUtilsHelper
  
  test "1- should return two hollidays" do
    start_date = "2017-04-10".to_date
	end_date = "2017-04-18".to_date
	@utils = Utils.new()
	issue = Issue.find(19)
    assert_equal 2, @utils.get_hollidays_between(start_date, end_date, issue.project, @utils.get_place(issue.assigned_to))
  end
  
  test "2 - should return two hollidays" do
    start_date = "2017-04-11".to_date
	end_date = "2017-04-18".to_date
	@utils = Utils.new()
	issue = Issue.find(19)
    assert_equal 2, @utils.get_hollidays_between(start_date, end_date, issue.project, @utils.get_place(issue.assigned_to))
  end
  
  test "should return one hollidays" do
    start_date = "2017-04-12".to_date
	end_date = "2017-04-18".to_date
	@utils = Utils.new()
	issue = Issue.find(19)
    assert_equal 1, @utils.get_hollidays_between(start_date, end_date, issue.project, @utils.get_place(issue.assigned_to))
  end
  
  test "should return 0 hollidays" do
    start_date = "2017-04-12".to_date
	end_date = "2017-04-17".to_date
	@utils = Utils.new()
	issue = Issue.find(19)
    assert_equal 0, @utils.get_hollidays_between(start_date, end_date, issue.project, @utils.get_place(issue.assigned_to))
  end
  
  test "1 - should return five days" do
    start_date = "2017-05-01".to_date
	end_date = "2017-05-05".to_date
	@utils = Utils.new()
    assert_equal 5, @utils.calc_days_between_date(start_date, end_date)
  end
  
  test "2 - should return five days" do
    start_date = "2017-05-01".to_date
	end_date = "2017-05-06".to_date
	@utils = Utils.new()
    assert_equal 5, @utils.calc_days_between_date(start_date, end_date)
  end
  
  test "3 - should return five days" do
    start_date = "2017-05-01".to_date
	end_date = "2017-05-07".to_date
	@utils = Utils.new()
    assert_equal 5, @utils.calc_days_between_date(start_date, end_date)
  end
  
  test "should return six days" do
    start_date = "2017-05-01".to_date
	end_date = "2017-05-08".to_date
	@utils = Utils.new()
    assert_equal 6, @utils.calc_days_between_date(start_date, end_date)
  end
  
  test "should return 0 weekenddays" do
    start_date = "2017-05-01".to_date
	end_date = "2017-05-05".to_date
	@utils = Utils.new()
    assert_equal 0, @utils.calc_weekenddays_between_date(start_date, end_date)
  end
  
  test "1 - should return 2 weekenddays" do
    start_date = "2017-05-01".to_date
	end_date = "2017-05-08".to_date
	@utils = Utils.new()
    assert_equal 2, @utils.calc_weekenddays_between_date(start_date, end_date)
  end
  
  test "2 - should return 2 weekenddays" do
    start_date = "2017-05-03".to_date
	end_date = "2017-05-12".to_date
	@utils = Utils.new()
    assert_equal 2, @utils.calc_weekenddays_between_date(start_date, end_date)
  end
  
  test "should return 3 weekenddays" do
    start_date = "2017-05-03".to_date
	end_date = "2017-05-13".to_date
	@utils = Utils.new()
    assert_equal 3, @utils.calc_weekenddays_between_date(start_date, end_date)
  end
  
  test "1 - should return 4 weekenddays" do
    start_date = "2017-05-03".to_date
	end_date = "2017-05-14".to_date
	@utils = Utils.new()
    assert_equal 4, @utils.calc_weekenddays_between_date(start_date, end_date)
  end
  
  test "2 - should return 4 weekenddays" do
    start_date = "2017-05-03".to_date
	end_date = "2017-05-16".to_date
	@utils = Utils.new()
    assert_equal 4, @utils.calc_weekenddays_between_date(start_date, end_date)
  end
  
  test "Asignacion should be 16hs" do
	issue = Issue.find(4)
	@utils = Utils.new()
    assert_equal 16.0, @utils.get_asignacion(issue)
  end
  
  test "Asignacion should be 4hs" do
	issue = Issue.find(6)
	@utils = Utils.new()
    assert_equal 4.0, @utils.get_asignacion(issue)
  end
  
  test "1 - Asignacion should be 8hs" do
	issue = Issue.find(5)
	@utils = Utils.new()
    assert_equal 8.0, @utils.get_asignacion(issue)
  end
  
  test "2 - Asignacion should be 8hs" do
	issue = Issue.find(3)
	@utils = Utils.new()
    assert_equal 8.0, @utils.get_asignacion(issue)
  end
  
  test "Asignacion should be 6hs" do
	issue = Issue.find(19)
	@utils = Utils.new()
    assert_equal 6.0, @utils.get_asignacion(issue)
  end
  
  test "End date should be 2017-05-11" do
	issue = Issue.find(19)
	@utils = Utils.new()
	issue.due_date = "2017-05-20".to_date
	assert_equal "2017-05-20".to_date, issue.due_date
	@utils.update_issue_end_date(issue)
    assert_equal "2017-05-11".to_date, issue.due_date
  end
  
  test "1 - Start date should be 2017-05-02" do
	@utils = Utils.new()
	issue = Issue.find(19)
	issue.start_date = "2017-04-29".to_date
	assert_equal "2017-05-02".to_date, @utils.cal_start_date(issue)
  end
  
   test "2 - Start date should be 2017-05-02" do
	@utils = Utils.new()
	issue = Issue.find(19)
	issue.start_date = "2017-04-30".to_date
	assert_equal "2017-05-02".to_date, @utils.cal_start_date(issue)
  end
  
  test "End date should be 2017-04-17" do
	@utils = Utils.new()
	start_date = "2017-04-05".to_date
	end_date = start_date + 7
	issue = Issue.find(19)
    assert_equal "2017-04-17".to_date, @utils.cal_end_date(start_date, end_date, issue)
  end
  
end