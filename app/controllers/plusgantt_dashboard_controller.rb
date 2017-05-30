class PlusganttDashboardController < ApplicationController
  menu_item :plusgantt_dashboard
  before_filter :find_optional_project

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  helper :issues
  helper :projects
  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper
  include PlusganttIssuesHelper

  def show
	@issuesdate = IssueDate.new()
	Rails.logger.info("----------------show----------------------------")
  end
  
  def calculate
	@issuesdate = IssueDate.new()
	retrieve_query
    @query.group_by = nil
    @issuesdate.query = @query if @query.valid?
	Rails.logger.info("----------------calculate----------------------------")
	issues_updated = @issuesdate.recalculate_issue_end_date(@project)
	if issues_updated >= 0
		flash[:notice] = "Issues: " + issues_updated.to_s
	else
		flash[:error] = @issuesdate.error
	end
	redirect_to :action => 'show'
  end

end
