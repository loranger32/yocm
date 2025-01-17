module Yocm
  class CBEUpdateManager

    def initialize(versions_checker)
      @versions_checker = versions_checker
    end

    def cli_check_status
      puts "**************************"
      puts "*  YOCM UPDATE MANAGER   *"
      puts "**************************"
      puts
      puts "Checking datasets versions"
      puts

      @versions_checker.display_all_versions
      puts

      @db_version = @versions_checker.versions.db
      @folder_version = @versions_checker.versions.data_folder
      @website_version = @versions_checker.versions.website

      status = compare_db_and_website
      display_options(status)
    end

    def auto_check_status
      versions = @versions_checker.versions
      @db_version = versions.db
      @folder_version = versions.data_folder
      @website_version = versions.website
      compare_db_and_website
    end

    def compare_db_and_website
      if db_empty?
        :empty_database
      elsif version_mismatch?
        :version_mismatch
      elsif up_to_date?
        :up_to_date
      elsif one_behind?
        :one_behind
      elsif many_behind?
        :many_behind
      else
        :too_many_behind
      end
    end

    private

      def clean_and_load
        puts "Data in the DB is too old, cannot perform udpate."
        puts "Clean the DB and load the latest full dataset."
        if $prompt.yes?("Ready to proceed ?")
          puts "Step 1: Deleting old data"
          Yocm::CBEDataHandler.new(db: DB).delete_cbe_data
          puts "Step 2: loading DB"
          load_db
        else
          puts "Operation aborted, exiting"
          exit
        end
      end

      def db_empty?
        @db_version.to_i.zero?
      end

      def display_options(status)
        case status
        when :up_to_date       then do_nothing
        when :empty_database   then load_db
        when :version_mismatch then fix_versions_mismatch
        when :one_behind       then update_one
        when :many_behind      then update_many
        when :too_many_behind  then clean_and_load
        else
          raise "Unknown status : #{status}"
        end
      end

      def do_nothing
        puts "Dataset is up to date"
      end

      def fix_versions_mismatch
        puts "The dataset version in your DB seems to be higher than the dataset available on CBE website, pleas check."
      end

      def folder_up_to_date?
        @folder_version == @website_version
      end

      def full_dataset?
        CSVMetaData.new.parse&.type == "full"
      end

      def no_dataset?
        CSVMetaData.new.parse.nil?
      end

      def update_dataset?
        !full_dataset?
      end

      def full_dataset_ready?
        full_dataset? && folder_up_to_date?
      end

      def update_dataset_ready?
        folder_up_to_date? && update_dataset?
      end

      def load_db
        puts "There is no data in the DB yet."

        if full_dataset_ready?
          puts "The latest full dataset is present in the DB folder."
        else
          if no_dataset?
            puts "Data folder is empty, need to download the full dataset."
          elsif !full_dataset?
            puts "The current dataset is of type 'update', need to download the full one."
          elsif !folder_up_to_date?
            puts "Dataset in folder is outdated, download the new one."
          else
            raise
          end

          if $prompt.yes?("Ready to download ?")
            CBEDataFetcher.new(db: DB, extract_number: @website_version, type: :full).fetch
            puts "The latest full dataset is now present in the DB folder."
          else
            puts "Download aborted."
          end
        end

        if $prompt.yes?("Do you want to load the dataset in the DB ?")
          Yocm::CBEDataHandler.new(db: DB).import
        else
          puts "DB not loaded"
        end
      end

      def many_behind?
        (2..4) === @website_version - @db_version
      end

      def one_behind?
        @db_version == @website_version - 1
      end

      def update_many
        puts "Method #update_many has not been implemented yet"
      end

      def update_one
        puts "Your DB is one version behind the CBE website."
        if update_dataset_ready?
          puts "New dataset is already available, ready to process update."
        else
          if $prompt.yes?("Dataset nr #{@website_version}, type 'update', has not been downloaded yet. Do you want to fetch it ?")
            CBEDataFetcher.new(db: DB, extract_number: @website_version, type: :update).fetch
            puts "Dataset downloaded."
          else
            puts "Download cancelled, exiting"
            return
          end
        end

        if $prompt.yes?("Do you want to update the DB ?")
          Yocm::CBEDataHandler.new(db: DB).update
          puts "Update complete and successful."
          db_version = @versions_checker.check_db_version
          puts "DB is now running with version #{db_version} dataset."
        else
          puts "DB not updated."
        end
      end

      def up_to_date?
        @db_version == @website_version
      end

      def version_mismatch?
        @db_version > @website_version
      end
  end
end
