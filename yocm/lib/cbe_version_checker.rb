module Yocm
  class CBEVersionChecker

    Versions = Data.define(:db, :data_folder, :website)

    def initialize(db: nil, web_agent: nil)
      @db = db
      @web_agent = web_agent
    end

    def check_db_version
      return "No DB object provided, unable to check DB version" unless @db

      metadata = DB[:cbe_metadata].order_by(:extract_number).last
      metadata ? metadata[:extract_number] : "No data in DB"
    end

    def check_data_folder_version
      if (md = CSVMetaData.new.parse)
        md.extract_number.to_i
      else
        "No metadata found in data folder"
      end
    end

    def check_website_version
      return "No web agent provided, unable to check website version" unless @web_agent
      @web_agent.available_data_sets.sort.last.to_i
    end

    def display_all_versions
      retrieve_all_versions
      puts <<~VERSIONS
          Extract version numbers are:

          - DB : \t\t#{versions.db}
          - Data folder : #{versions.data_folder}
          - CBE website : #{versions.website}
        VERSIONS
    end

    def retrieve_all_versions
      @versions = Versions.new(db: check_db_version, data_folder: check_data_folder_version, website: check_website_version)
    end

    def versions
      @versions || retrieve_all_versions
    end
  end
end
