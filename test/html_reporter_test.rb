# frozen_string_literal: true

require "fileutils"
require_relative "test_helpers"
require_relative "../yocm/lib/engine" # for access to the ReportData struct
require_relative "../yocm/lib/html_reporter_class"
require_relative "../yocm/lib/results_manager_class"



class ReportTest < Minitest::Test
  REPORTS_DIR = File.expand_path("test_data/reports", __dir__)
  FAKE_REPORT_DATE = "20220126"
  TEST_REPORT = File.join(REPORTS_DIR, "report_#{FAKE_REPORT_DATE}.html")

  # Must be kept in sync with the struct defined in engine.rb
  # ReportData = Struct.new(:start_time, :engine_version, :options, :user, :no_user_option, :target_date,
  #    :url, :total_known, :total_unknown, :zip_code_errors, :total_new, :total_files,
  #   :publications_saved, :ocr_scans_saved, :pngs_saved, :db_storage, :end_time, :elapsed_time,
  #   :zip_code_results, :enterprise_results)

  # Allow setting if id field on User instances
  User.strict_param_setting = false

  DEFAULT_DATA = Yocm::Engine::ReportData.new(
    start_time: Time.new(2022, 1, 27),
    engine_version: "0.0.1",
    options: {test: "test", blob: "blob"},
    user: User.new(id: 1, email: "active_user@example.com", active: true),
    no_user_option: false,
    target_date: "2022/01/26",
    url: "https://www.example.com",
    total_known: 1111,
    total_unknown: 2222,
    zip_code_errors: 3333,
    total_new: 4444,
    total_files: 5555,
    publications_saved: true,
    ocr_scans_saved: "OCR Scans successfully saved",
    pngs_saved: "PNG successfully saved",
    db_storage: false,
    end_time: Time.new(2022, 1, 27, 0, 1, 30),
    elapsed_time: 90.0,
    zip_code_results: Yocm::ResultsManager::ZipCodeResults.new(match: false, matching: nil),
    enterprise_results: Yocm::ResultsManager::EnterpriseResults.new(match: false, matching: nil))

  # hack to set an user id without touching DB
  DEFAULT_DATA.user.id = 1
  User.strict_param_setting = true

  def test_create_execution_report_without_user_feature
    assert Dir.exist?(REPORTS_DIR)
    refute File.exist?(TEST_REPORT)

    Yocm::HTMLReporter.create_report(DEFAULT_DATA, REPORTS_DIR, FAKE_REPORT_DATE)

    assert File.exist?(TEST_REPORT)

    report = File.read(TEST_REPORT)

    refute_empty report

    assert_includes report, "2022-01-27 00:00:00 +0100"
    assert_includes report, "0.0.1"
    assert_includes report, "test"
    assert_includes report, "blob"
    assert_includes report, "2022/01/26"
    assert_includes report, "https://www.example.com"
    assert_includes report, "1111"
    assert_includes report, "2222"
    assert_includes report, "3333"
    assert_includes report, "4444"
    assert_includes report, "5555"
    assert_includes report, "OCR Scans successfully saved"
    assert_includes report, "PNG successfully saved"
    assert_includes report, "90.0"
    assert_includes report, "2022-01-27 00:01:30 +0100"
  end

  def test_report_with_default_setting_and_active_user_present
    Yocm::HTMLReporter.create_report(DEFAULT_DATA, REPORTS_DIR, FAKE_REPORT_DATE)
    report = File.read(TEST_REPORT)

    assert_includes report, "No specific user selected, reports generated for the active user: active_user@example.com (id: 1)"
  end

  def test_report_with_no_user_option_explicitely_passed
    data = DEFAULT_DATA.dup
    data.no_user_option = true
    data.user = nil

    Yocm::HTMLReporter.create_report(data, REPORTS_DIR, FAKE_REPORT_DATE)
    report = File.read(TEST_REPORT)

    assert_includes report, "\"No user\" option provided - no user report generated"
  end

  def test_report_with_default_setting_and_no_active_user_present
    data = DEFAULT_DATA.dup
    data.no_user_option = false
    data.user = nil

    Yocm::HTMLReporter.create_report(data, REPORTS_DIR, FAKE_REPORT_DATE)
    report = File.read(TEST_REPORT)

    assert_includes report, "No specific user selected and no active user - no user report generated"
  end

  # No need to test for an non-existing user selected - program raise at the start if its the case.
  def test_report_with_existing_user_selected
    data = DEFAULT_DATA.dup
    data.no_user_option = false

    data.user = User.new(email: "selected@example.com", active: false)
    # hack to set user id without touching DB
    User.strict_param_setting = false
    data.user.id = 2
    User.strict_param_setting = true

    Yocm::HTMLReporter.create_report(data, REPORTS_DIR, FAKE_REPORT_DATE)
    report = File.read(TEST_REPORT)

    assert_includes report, "Specific user selected - report generated for user: selected@example.com (id: 2)"
  end

  def teardown
    FileUtils.rm_r(File.join(TEST_REPORT), secure: true) if File.exist?(TEST_REPORT)
  end
end
