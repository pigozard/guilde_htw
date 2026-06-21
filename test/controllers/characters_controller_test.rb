require "test_helper"

class CharactersControllerTest < ActionDispatch::IntegrationTest
  test "GET index is accessible without login" do
    get characters_path
    assert_response :success
  end

  test "POST clear_roster redirects non-admin" do
    sign_in_as users(:regular_user)
    post clear_roster_characters_path
    assert_redirected_to root_path
    assert_equal "Accès refusé.", flash[:alert]
  end

  test "POST clear_roster sets all characters in_roster to false for admin" do
    sign_in_as users(:admin_user)
    assert characters(:active_character).in_roster
    post clear_roster_characters_path
    assert_redirected_to characters_path
    assert_not characters(:active_character).reload.in_roster
  end

  test "POST reactivate reactivates own inactive character" do
    sign_in_as users(:regular_user)
    assert_not characters(:inactive_character).in_roster
    post reactivate_character_path(characters(:inactive_character))
    assert_redirected_to characters_path
    assert characters(:inactive_character).reload.in_roster
  end

  test "POST reactivate cannot reactivate another user's character" do
    sign_in_as users(:admin_user)
    post reactivate_character_path(characters(:inactive_character))
    assert_response :not_found
  end

  private

  def sign_in_as(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password" }
    }
  end
end
