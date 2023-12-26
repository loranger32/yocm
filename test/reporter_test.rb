# frozen_string_literal: true

require "fileutils"
require_relative "test_helpers"
require_relative "../yocm/lib/engine" # for access to the ReportData struct
require_relative "../yocm/lib/reporter_class"

class ReportTest < Minitest::Test
  REPORTS_DIR = File.expand_path("test_data/reports", __dir__)
  TEST_REPORT = File.join(REPORTS_DIR, "report_20220126.html")

  # # Must be kept in sync with the struct defined in engine.rb
  # ReportData = Struct.new(:start_time, :engine_version, :options, :target_date, :url,
  #   :total_known, :total_unknown, :zip_code_errors, :total_new, :total_files,
  #   :publications_saved, :ocr_scans_saved, :pngs_saved, :db_storage, :end_time, :elapsed_time)

  def test_create_execution_report
    assert Dir.exist?(REPORTS_DIR)
    refute File.exist?(TEST_REPORT)

    data = Yocm::Engine::ReportData.new

    data.start_time = Time.new(2022, 1, 27)
    data.engine_version = "0.0.1"
    data.options = {test: "test", blob: "blob"}
    data.target_date = "2022/01/26"
    data.url = "https://www.example.com"
    data.total_known = 1111
    data.total_unknown = 2222
    data.zip_code_errors = 3333
    data.total_new = 4444
    data.total_files = 5555
    data.publications_saved = true
    data.ocr_scans_saved = "OCR Scans successfully saved"
    data.pngs_saved = "PNG successfully saved"
    data.db_storage = false
    data.end_time = Time.new(2022, 1, 27, 0, 1, 30)
    data.elapsed_time = 90.0

    Yocm::Reporter.create_report(data, REPORTS_DIR, "20220126")

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

  def teardown
    FileUtils.rm_r(File.join(TEST_REPORT), secure: true) if File.exist?(TEST_REPORT)
  end
end
