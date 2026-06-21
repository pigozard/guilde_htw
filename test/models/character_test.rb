require "test_helper"

class CharacterTest < ActiveSupport::TestCase
  test "roster scope returns only in_roster permanent characters" do
    assert_includes Character.roster, characters(:active_character)
    assert_not_includes Character.roster, characters(:inactive_character)
    assert_not_includes Character.roster, characters(:temp_character)
  end

  test "out_of_roster scope returns only non-roster permanent characters" do
    assert_includes Character.out_of_roster, characters(:inactive_character)
    assert_not_includes Character.out_of_roster, characters(:active_character)
    assert_not_includes Character.out_of_roster, characters(:temp_character)
  end
end
