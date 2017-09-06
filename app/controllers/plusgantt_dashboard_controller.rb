class PlusganttDashboardController < ApplicationController
  menu_item :plusgantt_dashboard

  before_filter :init_cache, :only => [:init_run, :run]
  before_filter :find_optional_project
  before_filter :read_cache, :only => [:run]
  after_filter  :write_cache, :only => [:init_run, :run]
  
  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  helper :issues
  helper :projects
  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper
  include PlusganttDashboardHelper

  def show
	Rails.logger.info("----------------show----------------------------")
	flash.clear
	@dashboard = Dashboard.new(params)
	@dashboard.project = @project
	session[:finished] = false
	session[:current] = nil
  end
  
  def show_calculate
	Rails.logger.info("----------------show_calculate----------------------------")
	@dashboard = Dashboard.new(params)
	@dashboard.project = @project
	if session[:current] && session[:finished]
		flash[:notice] = l(:label_issue_plural) + ": " + session[:current].to_s
	end
	session[:finished] = false
	session[:current] = nil
	@@cache.clear
	render :action => 'show'
  end
  
  def run
	Rails.logger.info("run.................")
	if request.post?
		result = process_tasks({:max_items => max_items_per_request, :max_time => 10.seconds}, session[:current])
		if result < 0
			flash[:error] = @dashboard.error unless @dashboard && @dashboard.error.blank?
			flash[:notice] = l(:label_issue_plural) + ": " + session[:current].to_s
			redirect_to plusgantt_dashboard_show_calculate_path(:project_id => @project)
		else
			if session[:finished]
				Rails.logger.info("recalculate_predecessors_end_date.................")
				if @dashboard.recalculate_predecessors_end_date(@predecessors) < 0
					flash[:error] = @dashboard.error unless @dashboard && @dashboard.error.blank?
				end
			end
			respond_to do |format|
				format.html {
					if session[:finished]
						redirect_to plusgantt_dashboard_show_calculate_path(:project_id => @project)
					else
						Rails.logger.info("redirect run.................")
						redirect_to plusgantt_dashboard_run_path(:project_id => @project)
					end
				}
				Rails.logger.info("js run.................")
				format.js
			end
		end
	end
  end
  
  def init_run
    session[:finished] = false
	if params[:user_action] && params[:user_action] == 'calculate'
		@dashboard = Dashboard.new(params)
		@dashboard.project = @project
		if @dashboard.validate_conf == 0
			@issues = @dashboard.project_issues(@project)
			@relations = @dashboard.load_relations(@issues)
			@predecessors = Hash.new []
			redirect_to plusgantt_dashboard_run_path(:project_id => @project)
		else
			@issues =  []
			flash[:error] = @dashboard.error unless @dashboard && @dashboard.error.blank?
			redirect_to plusgantt_dashboard_show_calculate_path(:project_id => @project)
		end
	else
		redirect_to plusgantt_dashboard_show_calculate_path(:project_id => @project)
	end
  end
  
  private
  def init_cache
	tmp_path = Rails.root.join('tmp')
	unless File.writable? tmp_path.to_s
		flash[:error] = "Temp-Dir: '" + tmp_path.to_s + "' is not writable!"
	end
	@@cache = ActiveSupport::Cache::FileStore.new(Rails.root.join('tmp','plusgantt_dashboard').to_s)
  end
  
  def read_cache
	@issues  = @@cache.read(:issues)
	@relations  = @@cache.read(:relations)
	@predecessors = @@cache.read(:predecessors)
  end
  
  def write_cache
    @@cache.write(:issues, @issues)
	@@cache.write(:relations, @relations)
	@@cache.write(:predecessors, @predecessors)
  end
  
  def process_tasks(options={}, resume_after)
	@dashboard = Dashboard.new(params)
	@dashboard.project = @project
	max_items = options[:max_items]
    max_time = options[:max_time]
    processed = 0
	position = 1
	if resume_after.nil?
		resume_after = 0
	end
    interrupted = false
    started_on = Time.now

    @issues.each do |issue|
      if (max_items && processed >= max_items) || (max_time && Time.now >= started_on + max_time)
        interrupted = true
        break
      end
      if position > resume_after
        #Do process
        processed += 1
		result = @dashboard.recalculate_issue_end_date(issue, @relations, @predecessors)
		if result[:processed] < 0
			return result[:processed]
		else
			@predecessors = result[:predecessors]
		end
      end
	  position += 1
    end

    if processed == 0 || !interrupted
      session[:finished] = true
	else
		session[:finished] = false
    end
	
	return session[:current] = position - 1
  end
  
	def max_items_per_request
		5
	end
end
