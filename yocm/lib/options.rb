module Yocm
  class Options
    def initialize
      @params = {}
    end

    def parse
      OptionParser.new do |opts|
        opts.banner = "Usage: ./yocm/yocm.rb [options]"

        opts.on("-bDAYSBACK", "--days-back=DAYSBACK", Integer, "Select number of days before (0-30)(with -e or --engine)")

        opts.on("-d", "--debug-mode", "Set logger to debug level (with -e or --engine)")

        opts.on("-e", "--engine", "Run parsing engine")

        opts.on("-g", "--gui", "Launch the GUI")

        opts.on("-m", "--manage-update", "Launch CBE data update manager")

        opts.on("-s", "--skip-zipcodes", "Don't parse zip code (with -e or --engine)")

        # --local-files and --png-present flags are mostly useful in development
        opts.on("--local-files", "Process local publication files, no download")

        opts.on("--png-present", "PNGs already presents, don't do the conversion (no download)")

        opts.on("--devdb", "Interact with the development DB")

        opts.on("--import-cbe", "Import CBE data from data/cbe directory (need a full datatset)")

        opts.on("--update-cbe", "Update CBE data from data/cbe directory (need an update dataset)")

        opts.on("--import-zipcodes", "Import zip codes")

        opts.on("--clean-cbedata", "Delete all CBE data from database (but will leave the publications and zip codes data)")

        opts.on("--extract-versions", "Compare extract version numbers of DB, Data folder and CBE website")

        opts.on("--fetch-update=NUMBER", Integer, "Fetch update dataset nr NUMBER from the CBE website")

        opts.on("--check-setup", "Check if all required dependencies are satisfied")

        opts.on_tail("-v", "--version", "Show version") do
          puts "Yocm version: #{VERSION}"
          exit
        end

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end
      end.parse!(into: @params)

      self
    end

    def list
      @params
    end

    def days_back
      @params[:"days-back"]
    end

    def debug_mode?
      !@params[:"debug-mode"].nil?
    end

    def engine?
      !!@params[:engine]
    end

    def launch_gui?
      !!@params[:gui]
    end

    def devdb?
      !!@params[:devdb]
    end

    def import_cbe?
      !!@params[:"import-cbe"]
    end

    def update_cbe?
      !!@params[:"update-cbe"]
    end

    def import_zip_codes?
      !!@params[:"import-zipcodes"]
    end

    def delete_cbe_data?
      !!@params[:"clean-cbedata"]
    end

    def extract_version?
      !!@params[:"extract-versions"]
    end

    def png_present?
      !@params[:"png-present"].nil?
    end

    def fetch_update?
      !!@params[:"fetch-update"]
    end

    def fetch_update
      @params[:"fetch-update"]
    end

    alias dataset_version fetch_update

    def manage_update?
      !!@params[:"manage-update"]
    end

    def check_setup?
      !!@params[:"check-setup"]
    end

    def process_local_files?
      png_present? || !@params[:"local-files"].nil?
    end

    def skip_zipcodes?
      !@params[:"skip-zipcodes"].nil?
    end

    def data_operations?
      import_cbe? || update_cbe? || import_zip_codes? || delete_cbe_data? ||
      extract_version? || fetch_update? || manage_update?
    end
  end
end

