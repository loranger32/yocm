module Yocm
  # Abstract Class
  class DataHandler
    class Error < StandardError; end

    ALL_TABLES = %i[addresses branches cbe_metadata denominations enterprises establishments
      juridical_forms zip_codes].freeze

    def initialize(db:)
      validate_db(db)
      @db = db
      set_logging
    end

    def import
      raise StandardError, "Abstract class - not implemented"
    end

    private

    def set_logging
      return if ENV["RUN_ENV"] == "test"

      @db.loggers << Logger.new($stdout)
    end

    def validate_db(db)
      unless ALL_TABLES.all? { db.table_exists?(_1) }
        err_msg = "Missing required table in the DB, check your migrations."
        raise self.class::Error, err_msg
      end
    end
  end
end
