# frozen_string_literal: true

require "optparse"
require_relative "test_helpers"
require_relative "../yocm/lib/options"

class OptionTest < Minitest::Test
  def setup
    @options = Yocm::Options.new
  end

  ##############################
  # Options with short version #
  ##############################

  def test_days_back_short
    ARGV << "-b5"
    @options.parse
    assert_equal 5, @options.days_back
  end

  def test_days_back_long
    ARGV << "--days-back=5"
    @options.parse
    assert_equal 5, @options.days_back
  end

  def test_debug_mode_short
    ARGV << "-d"
    @options.parse
    assert @options.debug_mode?
  end

  def test_debug_mode_long
    ARGV << "--debug-mode"
    @options.parse
    assert @options.debug_mode?
  end

  def test_engine_short
    ARGV << "-e"
    @options.parse
    assert @options.engine?
  end

  def test_engine_long
    ARGV << "--engine"
    @options.parse
    assert @options.engine?
  end

  def test_gui_short
    ARGV << "-g"
    @options.parse
    assert @options.launch_gui?
  end

  def test_gui_long
    ARGV << "--gui"
    @options.parse
    assert @options.launch_gui?
  end

  def test_manage_update_short
    ARGV << "-m"
    @options.parse
    assert @options.manage_update?
  end

  def test_manage_update_long
    ARGV << "--manage-update"
    @options.parse
    assert @options.manage_update?
  end

  def test_skip_zipcodes_short
    ARGV << "-s"
    @options.parse
    assert @options.skip_zipcodes?
  end

  def test_skip_zipcodes_long
    ARGV << "--skip-zipcodes"
    @options.parse
    assert @options.skip_zipcodes?
  end

  def test_user_short
    ARGV << "-u2"
    @options.parse
    assert_equal 2, @options.user
  end

  def test_user_long
    ARGV << "--user=2"
    @options.parse
    assert_equal 2, @options.user
  end

  def test_no_user
    ARGV << "--no-user"
    @options.parse
    refute @options.user
  end


  ##################################
  # Options with long version only #
  ##################################

  def test_process_local_files
    ARGV << "--local-files"
    @options.parse
    assert @options.process_local_files?
  end

  def test_png_present
    ARGV << "--png-present"
    @options.parse
    assert @options.png_present?
  end

  def test_process_local_files_is_assumed_if_png_present_flag_is_set
    ARGV << "-p"
    @options.parse
    assert @options.process_local_files?
  end

  def test_list_returns_a_hash_with_correct_values
    ARGV << "-ds"
    ARGV << "--days-back=5"

    @options.parse

    assert_instance_of Hash, @options.list
    assert @options.list[:"debug-mode"]
    assert @options.list[:"skip-zipcodes"]
    assert_equal 5, @options.list[:"days-back"]
  end

  def test_devdb
    ARGV << "--devdb"
    @options.parse
    assert @options.devdb?
  end

  def test_import_cbe
    ARGV << "--import-cbe"
    @options.parse
    assert @options.import_cbe?
  end

  def test_update
    ARGV << "--update-cbe"
    @options.parse
    assert @options.update_cbe?
  end

  def test_zip_codes
    ARGV << "--import-zipcodes"
    @options.parse
    assert @options.import_zip_codes?
  end

  def test_delete_cbe_data
    ARGV << "--clean-cbedata"
    @options.parse
    assert @options.delete_cbe_data?
  end

  def test_extract_version
    ARGV << "--extract-version"
    @options.parse
    assert @options.extract_version?
  end

  def test_fetch_update
    ARGV << "--fetch-update=117"
    @options.parse
    assert @options.fetch_update?
    assert_equal 117, @options.fetch_update
  end

  def test_dataset_version
    ARGV << "--fetch-update=117"
    @options.parse
    assert_equal 117, @options.dataset_version
  end

  def test_check_setup
    ARGV << "--check-setup"
    @options.parse
    assert @options.check_setup?
  end
end
