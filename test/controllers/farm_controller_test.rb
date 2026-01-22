require "test_helper"

class FarmControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get farm_index_url
    assert_response :success
  end
end
