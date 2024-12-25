#!/usr/bin/env ruby
# frozen_string_literal: true

### Needed for the call with a symlink
this_file = __FILE__
this_file = File.readlink(this_file) if File.symlink?(this_file)

### Storing the origin directory to restore it later
origin_directory = Dir.pwd

### Placing process in this directory
Dir.chdir(File.dirname(this_file))

require "bundler/setup"
Bundler.require :default, :engine

Dotenv.load("../.env")

require "date"
require "erb"
require "fileutils"
require "logger"
require "open-uri"
require "optparse"
require "sequel"

require_relative "lib/cbe_data_handler"
require_relative "lib/cbe_web_agent"
require_relative "lib/cbe_data_fetcher"
require_relative "lib/cbe_version_checker"
require_relative "lib/cbe_update_manager"
require_relative "lib/csv_metadata"
require_relative "lib/data_handler"
require_relative "lib/data_manager"
require_relative "lib/date_retriever_class"
require_relative "lib/downloader_class"
require_relative "lib/engine"
require_relative "lib/html_reporter_class"
require_relative "lib/options"
require_relative "lib/png_convertor_class"
require_relative "lib/publication_factory_class"
require_relative "lib/results_manager_class"
require_relative "lib/setup_check"
require_relative "lib/uri_builder_class"
require_relative "lib/user_manager_class"
require_relative "lib/zip_code_data_handler"
require_relative "lib/zip_code_engine_module"
require_relative "../version"

CBE_DATA_DIR = ENV["DATA_DIR"] || File.expand_path(File.join("data", "cbe")).freeze
METADATA_FILE = File.join(CBE_DATA_DIR, "meta.csv").freeze

$prompt = TTY::Prompt.new
$pastel = Pastel.new

options = Yocm::Options.new.parse
ENV["RUN_ENV"] = "development" if options.devdb?

if options.check_setup?
  Yocm::SetupCheck.new.display_checks
  exit
end

Yocm::SetupCheck.new.check_setup!(:db)

if options.launch_gui?
  ### Placing process in root directory, needed to properly access the public folder
  Dir.chdir("../")
  system("RACK_ENV=production bundle exec rackup app/config.ru")
end

require_relative "../db/db"

if options.data_operations?
  Yocm::DataManager.new(options).run
elsif options.engine?
  Yocm::Engine.new(options:, origin_dir: origin_directory).run
else
  puts "No options provided, exiting"
  exit
end

at_exit do
  DB.disconnect
  Dir.chdir(origin_directory)
end
