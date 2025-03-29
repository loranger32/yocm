require_relative "data_handler"

module Yocm
  class CBEDataHandler < DataHandler
    class Error < StandardError; end

    CBE_TABLES = %i[addresses branches cbe_metadata denominations enterprises establishments juridical_forms].freeze

    DATA = {dir: ENV["CBE_DATA_DIR"] || File.expand_path(File.join("..", "data", "cbe"), __dir__), # CBE_DATA_DIR env variable needed for tests
            addresses: {all: "address.csv",
                        old: "address_delete.csv",
                        new: "address_insert.csv"},
            branches: {all: "branch.csv",
                       old: "branch_delete.csv",
                       new: "branch_insert.csv"},
            cbe_metadata: "meta.csv",
            codes: "code.csv",
            denominations: {all: "denomination.csv",
                            old: "denomination_delete.csv",
                            new: "denomination_insert.csv"},
            enterprises: {all: "enterprise.csv",
                          old: "enterprise_delete.csv",
                          new: "enterprise_insert.csv"},
            establishments: {all: "establishment.csv",
                             old: "establishment_delete.csv",
                             new: "establishment_insert.csv"}}.freeze

    def delete_cbe_data
      DB.transaction do
        CBE_TABLES.each { DB[_1].delete }
      end
      puts "CBE tables have been cleaned " \
        "(#{CBE_TABLES.join(", ")}).Publications and zip codes unaffected."
    end

    def import
      ensure_no_preexisting_cbe_data

      report = []

      @db.transaction do
        report << import_cbe_metadata
        report << import_juridical_forms
        report << import_branches
        report << import_establishments
        report << import_enterprises
        report << import_denominations
        report << import_addresses
      rescue Error => e
        puts e.backtrace
        raise Sequel::Rollback
      end
      puts report
    end

    def update
      ensure_data_to_update
      ensure_data_continuity

      @db.transaction do
        update_enterprises
        update_addresses
        update_branches
        update_denominations
        update_establishments
        update_juridical_forms
        import_cbe_metadata
      rescue Error => e
        puts e.backtrace
        raise Sequel::Rollback
      end
    end

    private

    def ensure_data_continuity
      meta_csv_number = CSVMetaData.new.parse!.extract_number.to_i
      extract_numbers = DB[:cbe_metadata].select(:extract_number).all.map(&:values).flatten

      if extract_numbers.empty?
        err_msg = "No extract number found, cannot check continuity"
        raise Error, err_msg
      elsif extract_numbers.max == meta_csv_number
        err_msg = "Data seems up to date, aborting."
        raise Error, err_msg
      elsif extract_numbers.max != meta_csv_number - 1
        err_msg = "Update data doesn't match :Last extract version : #{extract_numbers.max}, update version: #{meta_csv_number}"
        raise Error, err_msg
      end
    end

    def ensure_data_to_update
      CBE_TABLES.each do |table|
        if DB[table].count.zero?
          err_msg = "No data to update in table #{table}, aborting."
          raise Error, err_msg
        end
      end
    end

    def ensure_no_preexisting_cbe_data
      CBE_TABLES.each do |table|
        unless DB[table].count.zero?
          err_msg = "Data still present in the table #{table}, aborting import all operation."
          raise Error, err_msg
        end
      end
    end

    def delete_addresses(file_name)
      @db.transaction(rollback: :reraise) do
        process(file_name) do |record|
          @db[:addresses].where(id: record[0]).delete
        end
      end
    end

    def delete_branches(file_name)
      @db.transaction(rollback: :reraise) do
        process(file_name) do |record|
          @db[:branches].where(id: record[0]).delete
        end
      end
    end

    def delete_denominations(file_name)
      @db.transaction(rollback: :reraise) do
        process(file_name) do |record|
          @db[:denominations].where(enterprise_id: record[0]).delete
        end
      end
    end

    def delete_enterprises(file_name)
      @db.transaction(rollback: :reraise) do
        process(file_name) do |record|
          @db[:enterprises].where(id: record[0]).delete
        end
      end
    end

    def delete_establishments(file_name)
      @db.transaction(rollback: :reraise) do
        process(file_name) do |record|
          @db[:establishments].where(id: record[0]).delete
        end
      end
    end

    def delete_juridical_forms
      @db.transaction(rollback: :reraise) { @db[:juridical_forms].delete }
    end

    def import_addresses
      start_time = Time.now
      insert_addresses(DATA[:addresses][:all])
      "Addresses imported in #{Time.now - start_time}"
    end

    def import_branches
      start_time = Time.now
      insert_branches(DATA[:branches][:all])
      "Branches imported in #{Time.now - start_time}"
    end

    def import_cbe_metadata
      report_data = []
      @db.transaction(rollback: :reraise) do
        File.open(File.join(DATA[:dir], DATA[:cbe_metadata])) do |f|
          metadata = CSV.parse(f)
          DB[:cbe_metadata].insert(snapshot_date: metadata[1][1],
            extract_time_stamp: metadata[2][1],
            extract_type: metadata[3][1],
            extract_number: metadata[4][1],
            version: metadata[5][1])

          report_data << metadata[3][1]
          report_data << metadata[4][1]
        end
      end
      "cbe_metadata imported. Type: #{report_data[0]}, number: #{report_data[1]}"
    end

    def import_denominations
      start_time = Time.now
      insert_denominations(DATA[:denominations][:all])
      "Denominations imported in #{Time.now - start_time}"
    end

    def import_enterprises
      start_time = Time.now
      insert_enterprises(DATA[:enterprises][:all])
      "Enterprises imported in #{Time.now - start_time}"
    end

    def import_establishments
      start_time = Time.now
      insert_establishments(DATA[:establishments][:all])
      "Establishments imported in #{Time.now - start_time}"
    end

    def import_juridical_forms
      start_time = Time.now
      insert_juridical_forms
      "Juridical forms imported in #{Time.now - start_time}"
    end

    def insert_addresses(file_name)
      @db.transaction(rollback: :reraise) do
        process(file_name) do |record|
          @db[:addresses].insert(id: record[0],
            type_of_address: record[1],
            country_nl: record[2],
            country_fr: record[3],
            zip_code: record[4],
            municipality_nl: record[5],
            municipality_fr: record[6],
            street_nl: record[7],
            street_fr: record[8],
            house_number: record[9],
            box: record[10],
            extra_address_info: record[11],
            date_striking_of: record[12])
        end
      end
    end

    def insert_branches(file_name)
      @db.transaction(rollback: :reraise) do
        process(file_name) do |record|
          @db[:branches].insert(id: record[0], start_date: record[1], enterprise_id: record[2])
        end
      end
    end

    def insert_denominations(file_name)
      @db.transaction(rollback: :reraise) do
        process(file_name) do |record|
          @db[:denominations].insert(enterprise_id: record[0],
            language: record[1],
            type_of_denomination: record[2],
            denomination: record[3])
        end
      end
    end

    def insert_enterprises(file_name)
      @db.transaction(rollback: :reraise) do
        process(file_name) do |record|
          @db[:enterprises].insert(id: record[0],
            juridical_situation: record[2],
            type_of_enterprise: record[3],
            juridical_form_id: record[4],
            juridical_form_cac_id: record[5],
            start_date: record[6])
        end
      end
    end

    def insert_establishments(file_name)
      @db.transaction(rollback: :reraise) do
        process(file_name) do |record|
          @db[:establishments].insert(id: record[0], start_date: record[1],
            enterprise_id: record[2])
        end
      end
    end

    def insert_juridical_forms
      @db.transaction(rollback: :reraise) do
        process(DATA[:codes]) do |record|
          if record[0] == "JuridicalForm"
            @db[:juridical_forms].insert(code: record[1],
              language: record[2],
              name: record[3])
          end
        end
      end
    end

    def process(file_name, &block)
      CSV.foreach(File.join(DATA[:dir], file_name), headers: true) do |row|
        block.call(row)
      end
    end

    def update_addresses
      @db.transaction(rollback: :reraise) do
        delete_addresses(DATA[:addresses][:old])
        insert_addresses(DATA[:addresses][:new])
      end
    end

    def update_branches
      @db.transaction(rollback: :reraise) do
        delete_branches(DATA[:branches][:old])
        insert_branches(DATA[:branches][:new])
      end
    end

    def update_denominations
      @db.transaction(rollback: :reraise) do
        delete_denominations(DATA[:denominations][:old])
        insert_denominations(DATA[:denominations][:new])
      end
    end

    def update_enterprises
      @db.transaction(rollback: :reraise) do
        delete_enterprises(DATA[:enterprises][:old])
        insert_enterprises(DATA[:enterprises][:new])
      end
    end

    def update_establishments
      @db.transaction(rollback: :reraise) do
        delete_establishments(DATA[:establishments][:old])
        insert_establishments(DATA[:establishments][:new])
      end
    end

    def update_juridical_forms
      @db.transaction(rollback: :reraise) do
        delete_juridical_forms
        insert_juridical_forms
      end
    end
  end
end
