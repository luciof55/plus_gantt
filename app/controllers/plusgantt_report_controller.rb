class PlusganttReportController < ApplicationController
  menu_item :plusgantt_report
  before_filter :set_period
  before_action :check_create_rights, only: [:edit, :update, :create, :save]
  before_action :check_show_rights, only: [:show, :detail]
  before_action :load_status_options
  rescue_from Query::StatementInvalid, with: :query_statement_invalid

  helper :issues
  helper :projects
  helper :queries
  helper :sort
  include QueriesHelper
  include SortHelper
  include PlusganttDashboardHelper

  def show
    Rails.logger.info('----------------show----------------------------')
    flash.clear
    @dashboard = Dashboard.new(params)
    @list = []
    @list = PgReport.where('control_date = ?', @period).to_a
  end

  def create
    Rails.logger.info('----------------create----------------------------')
    flash.clear
    @dashboard = Dashboard.new(params)
    @list = @dashboard.create_reports_items(@period)
  end

  def save
    Rails.logger.info('----------------save----------------------------')
    flash.clear
    errors = ''
    set_period()
    @dashboard = Dashboard.new(params)
    if @dashboard.delete_reports_items(@period) >= 0
      @list = @dashboard.create_reports_items(@period)
      @list.each do |item|
        if params['hours_consumed_' + item.project.id.to_s] && !params['hours_consumed_' + item.project.id.to_s].blank?
          item.hours_consumed = params['hours_consumed_' + item.project.id.to_s].to_d
        end
        if params['hours_adjusted_' + item.project.id.to_s] && !params['hours_adjusted_' + item.project.id.to_s].blank?
          item.hours_adjusted = params['hours_adjusted_' + item.project.id.to_s].to_d
        end
        if params['status_' + item.project.id.to_s] && !params['status_' + item.project.id.to_s].blank?
          item.status = params['status_' + item.project.id.to_s].to_i
        end
        if !item.save()
           errors += '<ul>' + item.errors.full_messages.map{|o| '<li>' + o + '</li>' }.join('') + '</ul>'
        end
      end
    else
        errors = '<ul>Error al eliminar los reportes existentes<ul>'
    end

    if errors == ''
      flash[:notice] = 'Reports was successfully created.'
      render(:action => 'show')
    else
      flash[:error] = errors
      render(:action => 'create')
    end

  end

  def edit
    Rails.logger.info('----------------edit----------------------------')
    flash.clear
    @dashboard = Dashboard.new(params)
  end

  def detail
    Rails.logger.info('----------------detail----------------------------')
    flash.clear
    @dashboard = Dashboard.new(params)
  end

  private

  def check_create_rights
    right = User.current.allowed_to_globally?(:plusgantt_report_manage)
    if !right
      flash[:error] = translate 'no_right'
      redirect_to :back
    end
  end

  def check_show_rights
    right = User.current.allowed_to_globally?(:plusgantt_report)
    if !right
      flash[:error] = translate 'no_right'
      redirect_to :back
    end
  end

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
    @period = (Date.civil(@year_from, @month_from, 1) >> 1) - 1
  end

  def load_status_options
    @status_options = [[l(:status_red), -1], [l(:status_yellow), 0], [l(:status_green), 1]]
  end
end
