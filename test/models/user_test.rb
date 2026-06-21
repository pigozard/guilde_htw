require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "admin? returns true for admin user" do
    assert users(:admin_user).admin?
  end

  test "admin? returns false for regular user" do
    assert_not users(:regular_user).admin?
  end
end
