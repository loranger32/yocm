# frozen_string_literal: true

require_relative "test_helpers"
require_relative "../yocm/lib/date_retriever_class"

# IMPORTANT : when in test mode, day of running the test is fixed to be 27-02-2022, a thursday

DateRetriever = ::Yocm::DateRetriever

class DateRetrieverTest < Minitest::Test
  def test_accepts_an_integer_as_argument
    assert_silent { DateRetriever.new(days_back: 1) }
  end

  def test_throws_error_if_argument_is_not_integer
    invalid_arguments = ["1", :one, ["1"], [1]]
    invalid_arguments.each do |invalid_argument|
      assert_raises Yocm::DateRetriever::Error do
        DateRetriever.new(days_back: invalid_argument)
      end
    end
  end

  def test_date_returns_date_of_the_day_with_slahses
    assert_equal "2022/01/27", DateRetriever.new(days_back: 0).date
  end

  def test_date_returns_correct_date_when_days_back_is_not_zero_and_not_weekend
    assert_equal "2022/01/26", DateRetriever.new(days_back: 1).date
    assert_equal "2022/01/25", DateRetriever.new(days_back: 2).date
    assert_equal "2022/01/24", DateRetriever.new(days_back: 3).date
    assert_equal "2022/01/21", DateRetriever.new(days_back: 6).date
    assert_equal "2022/01/20", DateRetriever.new(days_back: 7).date
  end

  def test_directory_name_format_returns_date_without_slashes
    assert_equal "20220127", DateRetriever.new(days_back: 0).directory_name_format
  end

  def test_raises_if_days_back_points_to_a_saturday_or_sunday
    assert_raises(Yocm::DateRetriever::Error) { DateRetriever.new(days_back: 4) }
    assert_raises(Yocm::DateRetriever::Error) { DateRetriever.new(days_back: 5) }
  end
end
