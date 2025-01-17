# frozen_string_literal: true

require "fileutils"
require_relative "test_helpers"
require_relative "../yocm/lib/engine" # for access to the ReportData struct
require_relative "../yocm/lib/html_reporter_class"
require_relative "../yocm/lib/results_manager_class"


class HTMLReporterTest < HookedTestClass
  REPORTS_DIR = File.expand_path("test_data/reports", __dir__)
  FAKE_REPORT_DATE = "20220126"
  TEST_REPORT = File.join(REPORTS_DIR, "report_#{FAKE_REPORT_DATE}.html")

  # Save some typing
  ZipCodeResult = Yocm::ResultsManager::ZipCodeResult
  ZipCodeResults = Yocm::ResultsManager::ZipCodeResults
  EnterpriseResult = Yocm::ResultsManager::EnterpriseResult
  EnterpriseResults = Yocm::ResultsManager::EnterpriseResults

  # Must be kept in sync with the struct defined in engine.rb
  # ReportData = Struct.new(:start_time, :engine_version, :options, :user, :no_user_option, :user_selected, :target_date,
  #    :url, :total_known, :total_unknown, :zip_code_errors, :total_new, :total_files, :cpu_info,
  #   :publications_saved, :ocr_scans_saved, :pngs_saved, :db_storage, :end_time, :elapsed_time,
  #   :zip_code_results, :enterprise_results)

  def around
    DB.transaction(rollback: :always) do
      @user = User.create(email: "active_user@example.com", active: true)
      super
    end
  end

  def default_data(user)
    Yocm::Engine::ReportData.new(
      start_time: Time.new(2022, 1, 27),
      engine_version: "0.0.1",
      options: {test: "test", blob: "blob"},
      user: user,
      no_user_option: false,
      user_selected: false,
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
      elapsed_time: "1 minute and 30 seconds",
      cpu_info: "2 CORES - a good CPU",
      zip_code_results: Yocm::ResultsManager::ZipCodeResults.new(match: false, matching: nil),
      enterprise_results: Yocm::ResultsManager::EnterpriseResults.new(match: false, matching: nil))
  end

  def test_create_execution_report_without_user_feature
    assert Dir.exist?(REPORTS_DIR)
    refute File.exist?(TEST_REPORT)

    data = default_data(@user)
    Yocm::HTMLReporter.create_report(data, REPORTS_DIR, FAKE_REPORT_DATE)

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
    assert_includes report, "1 minute and 30 seconds"
    assert_includes report, "2022-01-27 00:01:30 +0100"
    assert_includes report, "2 CORES - a good CPU"
  end

  def test_report_with_default_setting_and_active_user_present
    data = default_data(@user)
    Yocm::HTMLReporter.create_report(data, REPORTS_DIR, FAKE_REPORT_DATE)
    report = File.read(TEST_REPORT)

    assert_includes report, "No specific user selected, reports generated for the active user: active_user@example.com (id: 1)"
  end

  def test_report_with_no_user_option_explicitely_passed
    data = default_data(nil)
    data.no_user_option = true

    Yocm::HTMLReporter.create_report(data, REPORTS_DIR, FAKE_REPORT_DATE)
    report = File.read(TEST_REPORT)

    assert_includes report, "\"No user\" option provided - no user report generated"
  end

  def test_report_with_default_setting_and_no_active_user_present
    data = default_data(nil)

    Yocm::HTMLReporter.create_report(data, REPORTS_DIR, FAKE_REPORT_DATE)
    report = File.read(TEST_REPORT)

    assert_includes report, "No specific user selected and no active user - no user report generated"
  end

  # No need to test for an non-existing user selected - program raise at the start if its the case.
  def test_report_with_existing_user_selected
    user = User.create(email: "selected@example.com", active: false)
    data = default_data(user)
    data.user_selected = true

    Yocm::HTMLReporter.create_report(data, REPORTS_DIR, FAKE_REPORT_DATE)
    report = File.read(TEST_REPORT)

    assert_includes report, "Specific user selected - report generated for user: selected@example.com (id: 2)"
  end

  def test_report_with_user_selected_who_has_no_zip_codes_nor_enterprise
    data = default_data(@user)

    Yocm::HTMLReporter.create_report(data, REPORTS_DIR, FAKE_REPORT_DATE)
    report = File.read(TEST_REPORT)

    assert_includes report, "No zip codes selected for user"
    assert_includes report, "No enterprise selected for user"
  end

  def test_report_with_zip_codes_and_enterprises_results
    matching_zips = [ZipCodeResult.new(code: "4000", num_matches: 3),
                     ZipCodeResult.new(code: "1000", num_matches: 5)]
    zip_code_results = ZipCodeResults.new(match: true, matching: matching_zips)

    matching_enterprises = [EnterpriseResult.new(cbe_number: "0111.111.111", denomination: "ASBL 1"),
                            EnterpriseResult.new(cbe_number: "0222.222.222", denomination: "VZW 2")]
    enterprise_results = EnterpriseResults.new(match: true, matching: matching_enterprises)

    # Add just one fake city to allow checking for selected zip codes
    @user.add_zip_code(ZipCode.create(code: "9999", city_fr: "test city", city_nl: "test city"))
    # Add just one fake enterprise to allow checking for selected enterprise
    DB[:enterprises].insert(id: "0111.111.111", juridical_situation: "001", type_of_enterprise: "1", start_date: Date.today)
    @user.add_enterprise(Enterprise.first)

    data = default_data(@user)
    data.zip_code_results = zip_code_results
    data.enterprise_results = enterprise_results

    Yocm::HTMLReporter.create_report(data, REPORTS_DIR, FAKE_REPORT_DATE)
    report = File.read(TEST_REPORT)

    assert_includes report, "4000"
    assert_includes report, "3"
    assert_includes report, "1000"
    assert_includes report, "5"

    assert_includes report, "0111.111.111"
    assert_includes report, "0222.222.222"
    assert_includes report, "ASBL 1"
    assert_includes report, "VZW 2"
  end

  def teardown
    FileUtils.rm_r(File.join(TEST_REPORT), secure: true) if File.exist?(TEST_REPORT)
  end
end
