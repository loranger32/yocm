# frozen_string_literal: true

require "bundler/setup"
Bundler.require :default, :test, :engine, :gui
require "minitest/autorun"
require "minitest/reporters"
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
Dotenv.load("../.env")
ENV["CBE_DATA_DIR"] = File.expand_path(File.join("test_data", "cbe"), __dir__)
ENV["ZIP_DATA_DIR"] = File.expand_path(File.join("test_data", "zip_codes", "zip_codes.csv"), __dir__)
ENV["METADATA_FILE"] = File.join(ENV["CBE_DATA_DIR"], "meta.csv")
ENV["RUN_ENV"] = "test"

METADATA_FILE = ENV["METADATA_FILE"]

require_relative "../db/db"


$log = TTY::Logger.new do |config|
  config.handlers = [:null]
end

class HookedTestClass < Minitest::Test
  include Minitest::Hooks
end
