# frozen_string_literal: true

require_relative "test_helpers"
require_relative "../yocm/lib/zip_code_data_handler"

class ZipCodeDataHandlerTest < HookedTestClass
  def before_all
    super
    @zc_data_handler = Yocm::ZipCodeDataHandler.new(db: DB)
  end

  def around
    DB.transaction(rollback: :always, savepoint: true, auto_savepoint: true) do
      super
    end
  end

  def around_all
    DB.transaction(:rollback=>:always) do
      super
    end
  end

  def test_import_zip_codes_when_no_zip_code_present
    assert DB[:zip_codes].empty?
    capture_io { @zc_data_handler.import }
    assert_equal Yocm::ZipCodeDataHandler::ZIP_CODE_SIZE, DB[:zip_codes].count
  end

  def test_zip_code_first_entry_is_the_unknown_zip_code
    capture_io { @zc_data_handler.import }
    unknown_zip = DB[:zip_codes].where(city_fr: "unknown").first 
    assert_equal 1, unknown_zip[:id]
  end

  def test_zip_codes_primary_key_is_always_reset_before_importing
    assert DB[:zip_codes].empty?
    capture_io { @zc_data_handler.import }
    DB[:zip_codes].delete
    assert_equal 0, DB[:zip_codes].count
    capture_io { @zc_data_handler.import }
    assert_equal 1, DB[:zip_codes].where(city_fr: "unknown").first[:id]
  end

  def test_does_not_import_zip_codes_when_zip_codes_already_present
    assert DB[:zip_codes].empty?
    capture_io { @zc_data_handler.import }
    assert_raises(Yocm::ZipCodeDataHandler::Error) { @zc_data_handler.import }
    assert DB[:zip_codes].count == Yocm::ZipCodeDataHandler::ZIP_CODE_SIZE
  end

  def test_does_not_import_zip_code_when_one_zip_code_but_not_all_is_present
    assert DB[:zip_codes].empty?
    DB[:zip_codes].insert(code: "9999", city_fr: "Fake city", city_nl: "Fake city")
    assert DB[:zip_codes].count == 1
    assert_raises(Yocm::ZipCodeDataHandler::Error) { @zc_data_handler.import }
    assert DB[:zip_codes].count == 1
  end
end
