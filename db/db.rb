require "sequel"
require "logger"

module Yocm
  DB_NAME = "yocm.db"
  DEV_DB_NAME = "yocm_dev.db"
  TEST_DB_NAME = "yocm_test.db"

  base_db_path = if ENV["BASE_DB_PATH"] && File.absolute_path?(ENV["BASE_DB_PATH"])
    ENV["BASE_DB_PATH"]
  else
    File.expand_path(__dir__)
  end

  if [ENV["RACK_ENV"], ENV["RAKE_CONSOLE_ENV"], ENV["RUN_ENV"]].any? { _1 == "test" }
    DB = Sequel.sqlite(File.join(File.expand_path(__dir__), TEST_DB_NAME))
  elsif [ENV["RAKE_CONSOLE_ENV"], ENV["RUN_ENV"]].any? { _1 == "development" }
    DB = Sequel.sqlite(File.join(base_db_path, DEV_DB_NAME))
  else
    DB = Sequel.sqlite(File.join(base_db_path, DB_NAME))
  end

  DB.loggers << Logger.new($stdout) if %w[development set_logging].include?(ENV["RAKE_CONSOLE_ENV"])
end

DB = Yocm::DB # Save some typing when in irb console

Dir[File.expand_path("models/*", __dir__)].each { require_relative _1 }
