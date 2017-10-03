class PlusganttReportController < ApplicationController
  menu_item :plusgantt_report
  before_filter :set_period
  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  helper :issues
  helper :projects
  helper :queries
  helper :sort
  include QueriesHelper
  include SortHelper
  include PlusganttDashboardHelper

  def show
	Rails.logger.info("----------------show----------------------------")
	flash.clear
	@dashboard = Dashboard.new(params)
  end
  
  def create
	Rails.logger.info("----------------create----------------------------")
	flash.clear
	@dashboard = Dashboard.new(params)
	@list = @dashboard.create_reports_items(@period)
  end
  
   def save
	Rails.logger.info("----------------save----------------------------")
	flash.clear
  end
  
  def edit
	Rails.logger.info("----------------edit----------------------------")
	flash.clear
	@dashboard = Dashboard.new(params)
  end
  
  def detail
	Rails.logger.info("----------------detail----------------------------")
	flash.clear
	@dashboard = Dashboard.new(params)
  end
  
  private
  
  def set_period
	if params[:year] && params[:year].to_i > 0
		@year_from = params[:year].to_i
		if params[:month] && params[:month].to_i >=1 && params[:month].to_i <= 12
			@month_from = params[:month].to_i
		else
			@month_from = 1
		end
	else
		@month_from ||= User.current.today.month
		@year_from ||= User.current.today.year
	end
	@period  = (Date.civil(@year_from, @month_from, 1) >> 1) - 1
  end

end
