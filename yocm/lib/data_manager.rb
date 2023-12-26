module Yocm
  class DataManager
    def initialize(options)
      @options = options
    end

    def run
      if @options.manage_update?
        Yocm::CBEUpdateManager.new(Yocm::CBEVersionChecker.new(db: DB, web_agent: Yocm::CBEWebAgent.new)).cli_check_status
        exit
      end

      if @options.extract_version?
        Yocm::CBEVersionChecker.new(db: DB, web_agent: Yocm::CBEWebAgent.new).display_all_versions
        exit
      end

      if @options.fetch_update?
        Yocm::CBEDataFetcher.new(db: DB, extract_number: @options.dataset_version, type: :update).fetch
        exit
      end

      if @options.import_zip_codes?
        Yocm::ZipCodeDataHandler.new(db: DB).import
        exit
      end

      cbe_data_handler = Yocm::CBEDataHandler.new(db: DB)

      if @options.import?
        cbe_data_handler.import
        exit
      elsif @options.update?
        cbe_data_handler.update
        exit
      elsif @options.delete_cbe_data?
        if $prompt.yes?("Are you sure you want to clean the DB ? \
          This will delete all CBE data from the selected DB (publications data and zip codes will remain).")
          cbe_data_handler.delete_cbe_data
          puts "All CBE data in the DB have been deleted."
        else
          puts "Aborting cleanup of CBE data"
        end
        exit
      end
    end
  end
end
