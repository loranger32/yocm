module Yocm
  class App
    hash_branch("cbe-data") do |r|
      r.is do
        if CbeMetadata.count.zero?
          @no_data_in_db = true
          return view "cbe-data/index"
        end

        metadata = CbeMetadata.reverse(:extract_number).first
        @db_extract_number = metadata.extract_number
        @db_snapshot_date = metadata.snapshot_date
        @db_extract_time_stamp = metadata.extract_time_stamp
        @db_extract_type = metadata.extract_type

        @tables = [
          CbeTable.new("Enterprises", Enterprise.count),
          CbeTable.new("Denominations", Denomination.count),
          CbeTable.new("Addresses", Address.count),
          CbeTable.new("Establishments", Establishment.count),
          CbeTable.new("Branches", Branch.count),
          CbeTable.new("Juridical Froms", DB[:juridical_forms].count)
        ]

        if no_data_in_cbe_folder?
          @no_data_in_folder = true
          return view "cbe-data/index"
        end

        csv_metadata = retrieve_csv_metadata
        @csv_extract_number = csv_metadata[:extract_number]
        @csv_snapshot_date = csv_metadata[:snapshot_date]
        @csv_extract_timestamp = csv_metadata[:extract_time_stamp]
        @csv_extract_type = csv_metadata[:extract_type]

        @csv_files = retreive_csv_files_name

        view "cbe-data/index"
      end
    end
  end
end
