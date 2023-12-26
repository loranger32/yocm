require "bundler/setup"
Bundler.require(:default, :gui)

Dotenv.load

require_relative '../db/db'
DB.loggers << Logger.new($stdout)

require_relative 'helpers/app_helpers'
require_relative 'helpers/view_helpers'
require_relative 'app'

run Yocm::App.freeze.app
