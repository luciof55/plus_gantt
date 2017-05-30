require File.expand_path('../../test_helper', __FILE__)

class PlusganttControllerTest < ActionController::TestCase

	def test_show
		get :show, :project_id => 1

		assert_response :success
		assert_template 'show'
	end
	
	def test_show_error
		get :show, :project_id => 3

		assert_response :redirect
	end
end
