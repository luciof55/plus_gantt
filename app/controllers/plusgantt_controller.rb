class PlusganttController < ApplicationController
  menu_item :plusgantt
  before_filter :find_optional_project, :validate_param_date

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  helper :plusgantt
  helper :issues
  helper :projects
  helper :queries
  include QueriesHelper
  helper :sort
  include SortHelper
  include Redmine::Export::PDF
  include PlusganttChartHelper

  def show
	params.store('main_project', @project)
    @plusgantt = PlusganttChart.new(params)
    @plusgantt.project = @project
    retrieve_query
    @query.group_by = nil
    @plusgantt.query = @query if @query.valid?

    basename = (@project ? "#{@project.identifier}-" : '') + 'plusgantt'

    respond_to do |format|
      format.html { render :action => "show", :layout => !request.xhr? }
      format.png  { send_data(@plusgantt.to_image, :disposition => 'inline', :type => 'image/png', :filename => "#{basename}.png") } if @plusgantt.respond_to?('to_image')
      format.pdf  { send_data(@plusgantt.to_pdf, :type => 'application/pdf', :filename => "#{basename}.pdf") }
    end
  end
  
  private
  def validate_param_date
   if params[:control_date]
	   begin
		   Date.parse(params[:control_date])
		rescue ArgumentError
		  flash[:error] = l(:label_date_format_error)
		end
	end
end

end
