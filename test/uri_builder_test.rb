# frozen_string_literal: true

require_relative "test_helpers"
require_relative "../yocm/lib/uri_builder_class"

class UriBuilderTest < Minitest::Test
  def test_throws_error_if_wrong_date_format
    invalid_dates = ["2019/10/8", "19/10/08", "08/10/2019", "2019 10 18"]
    invalid_dates.each do |invalid_date|
      assert_raises(Yocm::UriBuilder::Error) do
        Yocm::UriBuilder.new(date: invalid_date)
      end
    end
  end

  def test_it_returns_the_correct_uri
    expected = "https://www.ejustice.just.fgov.be/tsv_pdf/2019/10/18/pdf.zip"
    assert_equal expected, Yocm::UriBuilder.new(date: "2019/10/18").build
  end
end
