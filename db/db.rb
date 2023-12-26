# frozen_string_literal: true

require "sequel"
require "logger"

module Yocm
  if [ENV["RACK_ENV"], ENV["RAKE_CONSOLE_ENV"], ENV["RUN_ENV"]].any? { _1 == "test" }
    DB = Sequel.connect(ENV["TEST_DATABASE_URL"])
  elsif [ENV["RAKE_CONSOLE_ENV"], ENV["RUN_ENV"]].any? { _1 == "development" }
    DB = Sequel.connect(ENV["DEV_DATABASE_URL"])
    DB.loggers << Logger.new($stdout)
  else
    DB = Sequel.connect(ENV["DATABASE_URL"])
  end
end

DB = Yocm::DB # Save some typing when in irb console

# Load models from rake
Dir[File.expand_path("db/models/*")].each { require_relative _1 }

# Load models from yocm.rb
Dir[File.expand_path("../db/models/*")].each { require_relative _1 }
