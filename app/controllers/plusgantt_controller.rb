class PlusganttController < ApplicationController
  menu_item :plusgantt
  before_action :find_optional_project

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
	# params.store('main_project', @project)
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

end
