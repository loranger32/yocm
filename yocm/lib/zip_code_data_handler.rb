require_relative "data_handler"

module Yocm
  class ZipCodeDataHandler < DataHandler
    class Error < StandardError; end

    ZIP_CODE_SIZE = 2765
    # ENV variable needed for the tests
    ZIP_CODE_SOURCE = ENV["ZIP_DATA_DIR"] || File.expand_path(File.join("data", "zip_codes", "zip_codes.csv")).freeze

    def import
      check_table_is_empty

      # zip_code 'id' is a primary key referenced by publications table (zip_code_id)
      @db.reset_primary_key_sequence(:zip_codes)

      @db.transaction do
        # Add the unknown zip code '0000' required by the engine, as the first record.
        @db[:zip_codes].insert(code: "0000", city_fr: "unknown", city_nl: "unknown")

        counter = 0
        CSV.foreach(ZIP_CODE_SOURCE) do |row|
          @db[:zip_codes].insert(code: row[0],
            village_fr: row[1],
            village_nl: row[2],
            city_fr: row[3],
            city_nl: row[4],
            province_fr: row[5],
            province_nl: row[6])
          counter += 1
        end

        # Ensure zip codes are consistent
        check_zip_codes_record_number
        puts "#{counter} records processed from #{ZIP_CODE_SOURCE}."
      end
    end

    private

    def check_table_is_empty
      present_zip_codes_count = @db[:zip_codes].count

      if present_zip_codes_count == ZIP_CODE_SIZE
        err_msg = "Zip codes are already present in the DB"
      elsif present_zip_codes_count != 0
        err_msg = "Some records are already present in the zip_code_table, but not all."
      end

      raise Error, err_msg unless err_msg.nil?
    end

    def check_zip_codes_record_number
      zip_codes_count = @db[:zip_codes].count

      if ZIP_CODE_SIZE == zip_codes_count
        puts "Zip codes imported successfully"
      else
        begin
          err_msg = "Must be #{ZIP_CODE_SIZE} zip codes, but found only #{zip_codes_count}."
          raise Error, err_msg
        rescue Error => e
          puts e.backtrace
          raise Sequel::Rollback
        end
      end
    end
  end
end

