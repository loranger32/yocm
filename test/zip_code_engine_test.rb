# frozen_string_literal: true

require_relative "test_helpers"
require_relative "../yocm/lib/zip_code_engine_module"
require_relative "../yocm/lib/zip_code_data_handler"

module ZipCodeEngineSharedTests
  def scan(text)
    case @method
    when :scan_fr then scan_fr(text)
    when :scan_nl then scan_nl(text)
    when :scan_de then scan_de(text)
    end
  end

  def test_it_recognizes_simple_value_with_space_before_and_space_after
    @targets.each do |target|
      assert_equal @fake_capture_group, scan(" #{target}#{@fake_text_space}")[1]
    end
  end

  def test_it_recognizes_simple_value_with_new_line_before_and_space_after
    @targets.each do |target|
      assert_equal @fake_capture_group, scan("\n#{target}#{@fake_text_space}")[1]
    end
  end

  def test_it_recognizes_simple_value_with_dash_before_and_space_after
    @targets.each do |target|
      assert_equal @fake_capture_group, scan("-#{target}#{@fake_text_space}")[1]
    end
  end

  def test_it_recognizes_simple_value_with_space_before_and_no_space_after
    @targets.each do |target|
      assert_equal @fake_capture_group, scan(" #{target}#{@fake_text_no_space}")[1]
    end
  end

  def test_it_recognizes_simple_value_with_new_line_before_and_no_space_after
    @targets.each do |target|
      assert_equal @fake_capture_group, scan("\n#{target}#{@fake_text_no_space}")[1]
    end
  end

  def test_it_recognizes_simple_value_with_dash_before_and_no_space_after
    @targets.each do |target|
      assert_equal @fake_capture_group, scan("-#{target}#{@fake_text_no_space}")[1]
    end
  end

  def test_it_recognizes_simple_value_with_space_before_and_no_colon
    @targets.each do |target|
      assert_equal @fake_capture_group, scan(" #{target}#{@fake_text_no_colon}")[1]
    end
  end

  def test_it_recognizes_simple_value_with_new_line_before_and_no_colon
    @targets.each do |target|
      assert_equal @fake_capture_group, scan("\n#{target}#{@fake_text_no_colon}")[1]
    end
  end

  def test_it_recognizes_simple_value_with_dash_before_and_no_colon
    @targets.each do |target|
      assert_equal @fake_capture_group, scan("-#{target}#{@fake_text_no_colon}")[1]
    end
  end
end

class ZipCodeEngineFrenchTest < Minitest::Test
  include Yocm::ZipCodeEngine
  include ZipCodeEngineSharedTests

  def setup
    @method = :scan_fr
    @targets = %w[Siège siège Siége siége Siege siege Siëge siëge uSiège usiège]
    @fake_capture_group = "42 Lost Road,\n 4321 Nowhere"
    @fake_text_space = " : #{@fake_capture_group}"
    @fake_text_no_space = ": #{@fake_capture_group}"
    @fake_text_no_colon = " #{@fake_capture_group}"
  end
end

class ZipCodeEngineDutchTest < Minitest::Test
  include Yocm::ZipCodeEngine
  include ZipCodeEngineSharedTests

  def setup
    @method = :scan_nl
    @targets = %w[Zetel zetel Zetet zetet Zetei zetei Zete! zete!
                  Zefel zefel Zefet zefet Zefei zefei Zefe! zefe!
                  Zelel zelel Zelet zelet Zelei zelei Zele! zele!]
    @fake_capture_group = "42 Lost Road,\n 4321 Nowhere"
    @fake_text_space = " : #{@fake_capture_group}"
    @fake_text_no_space = ": #{@fake_capture_group}"
    @fake_text_no_colon = " #{@fake_capture_group}"
  end

  def test_it_recognizes_simple_value_with_dot_before
    @targets.each do |target|
      assert_equal @fake_capture_group, scan(".#{target}#{@fake_text_space}")[1]
    end
  end
end

class ZipCodeEngineGermanTest < Minitest::Test
  include Yocm::ZipCodeEngine
  include ZipCodeEngineSharedTests

  def setup
    @method = :scan_de
    @targets = %w[Sitz sitz Silz silz Siiz siiz
                  Sitze sitze Silze silze Siize siize
                  Sitzes sitzes Silzes silzes Siizes siizes]
    @fake_capture_group = "42 Lost Road,\n 4321 Nowhere"
    @fake_text_space = " : #{@fake_capture_group}"
    @fake_text_no_space = ": #{@fake_capture_group}"
    @fake_text_no_colon = " #{@fake_capture_group}"
  end
end

class ZipCodeEngineMainMethodTest < HookedTestClass
  include Yocm::ZipCodeEngine

  def before_all
    super
    capture_io { Yocm::ZipCodeDataHandler.new(db: DB).import }
  end

  def after_all
    DB[:zip_codes].delete
    super
  end

  # Mind the space before 'Siège' - required by the regexp
  def test_returns_a_string_0000_when_invalid_zip_code_provided
    source = " Siège : Lost Road 42, 4321 Nowhere"
    assert_equal "0000", retrieve_zip_code_from(source)
  end

  def test_returns_a_string_with_zip_code_when_valid_zip_code_provided
    source = " Siège : Lost Road 42, 2000 Antwerpen"
    assert_equal "2000", retrieve_zip_code_from(source)
  end

  def test_returns_0000_if_no_zip_code_found
    source = " Siège : Lost Road 42, 123 Nowhere"
    assert_equal "0000", retrieve_zip_code_from(source)
  end

  def test_returns_0000_if_no_match
    source = "No Match"
    assert_equal "0000", retrieve_zip_code_from(source)
  end

  def test_returns_correct_zip_code_if_multiple_four_digits_numbers_found
    source = " Siège : Lost Road 1999, 4000 Liège. Enterprise founded in 1894"
    assert_equal "4000", retrieve_zip_code_from(source)
  end
end
