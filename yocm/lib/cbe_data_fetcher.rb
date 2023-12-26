module Yocm
  class CBEDataFetcher < CBEWebAgent

    class InvalidCBEUrlError < StandardError; end

    UPDATE_TYPES = [:full, :update].freeze

    def initialize(db:, extract_number:, type:)
      validate_params(extract_number, type)
      super()
      add_save_directory
      @db = db
      @extract_number = extract_number
      @type = type
      @target_url_pattern = /KboOpenData_0#{@extract_number}_\d{4}_\d{2}_#{@type.to_s.capitalize}\.zip/
      @download_speed = @type == :full ? 1 : 6
      @bar = TTY::ProgressBar.new("Downloading [:bar]", total: 60)
    end

    def fetch
      authenticate
      puts "Authenticated"

      check_dataset_is_available
      puts "Dataset is available"

      url = retrieve_url
      puts "Url is #{url}"

      # Progress Bar animation
      Thread.new do
        while true do
          sleep(1)
          @bar.advance(@download_speed)
        end
      end

      @agent.get(url)
      @bar.finish

      file_name = archive_file_name(url)
      puts "Dataset archive downloaded in #{File.join(CBE_DATA_DIR, file_name)}"

      puts "Unzipping..."
      unzip_cbe_archive(file_name)
      puts "Dataset archive unzipped"

      # puts "Deleting archive..."
      # delete_archive(file_name)
      # puts "Archive deleted."

      display_dataset_metadata
    end

    private

      def add_save_directory
        @agent.pluggable_parser["application/zip"] = Mechanize::DirectorySaver.save_to(CBE_DATA_DIR)
      end

      # url is "files/name_of_the_archive_file.zip"
      def archive_file_name(url)
        url.delete_prefix("files/")
      end

      def check_dataset_is_available
        data_sets = available_data_sets

        unless data_sets.include?(@extract_number.to_s)
          puts "You asked dataset #{@extract_number}, but the available datasets are #{data_sets.join(", ")}."
          puts "Exiting..."
          exit
        end
      end

      def delete_archive(file_name)
        FileUtils.remove_entry_secure(File.join(CBE_DATA_DIR, file_name))
      end

      def display_dataset_metadata
        md = CSVMetaData.new.parse
        puts <<~METADATA
        Dataset infos :
        - Snapshot date :       #{md.snapshot_date}
        - Extract Timestamp :   #{md.extract_timestamp}
        - Extract Number :      #{md.extract_number}
        - Type :                #{md.type}
        - Format version :      #{md.format_version}
        METADATA
      end

      def retrieve_url
        url = @data_page.links_with(href: @target_url_pattern)&.first
        raise InvalidCBEUrlError, "No URL matching pattern #{target_url_pattern}" if url.nil?
        url.href
      end

      def validate_params(extract_number, type)
        validate_extract_number(extract_number)
        validate_type(type)
      end

      def validate_extract_number(extract_number)
        err_msg = "extract_number must be a 3 digit number, got #{extract_number} instead."
        raise ArgumentError, err_msg unless extract_number.to_s.match(/\A\d{3}\z/)
      end

      def validate_type(type)
        err_msg = "type must be :full or :update, got #{type} instead."
        raise ArgumentError, err_msg unless UPDATE_TYPES.include?(type)
      end

      def unzip_cbe_archive(file_name)
        cbe_zip = File.join(CBE_DATA_DIR, file_name)

        # YJIT needs to be disabled until Ruby 3.3
        # Check https://github.com/rubyzip/rubyzip/pull/550
        Zip.on_exists_proc = true # Configure RubyZip to allow rewriting existing files

        Zip::File.open(cbe_zip) do |zip_file|
          zip_file.each do |entry|
            entry.extract(destination_directory: CBE_DATA_DIR)
            puts "#{entry} unzipped."
          end
        end
      end
  end
end
