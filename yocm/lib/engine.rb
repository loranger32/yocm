module Yocm
  class Engine

    class Error < StandardError; end

    PATH_TO = {}
    PATH_TO[:index] = File.expand_path(File.join("..", "data", "index"), __dir__)
    PATH_TO[:logs] = File.expand_path(File.join("..", "data", "logs"), __dir__)
    PATH_TO[:ocr] = File.expand_path(File.join("..", "data", "ocr"), __dir__)
    PATH_TO[:png] = File.expand_path(File.join("..", "data", "png"), __dir__)
    PATH_TO[:reports] = File.expand_path(File.join("..", "data", "reports"), __dir__)
    PATH_TO[:unzipped] = File.expand_path(File.join("..", "data", "unzipped"), __dir__)
    PATH_TO[:zip] = File.expand_path(File.join("..", "data", "zip"), __dir__)
    PATH_TO[:app_public_folder] = File.expand_path(File.join("..", "..", "app", "public"), __dir__)
    PATH_TO.freeze

    ReportData = Struct.new(:start_time, :engine_version, :options, :target_date, :url,
                            :total_known, :total_unknown, :zip_code_errors, :total_new, :total_files,
                            :publications_saved, :ocr_scans_saved, :pngs_saved, :db_storage, :end_time, :elapsed_time)

    ParserResult = Struct.new(:file_name, :zip_code)
    OCRScans = Struct.new(:file_name, :scan)

    def initialize(options:, origin_dir:)
      @options = options
      @origin_directory = origin_dir
      setup_directories!
      config_logger

      ### Initial log messages
      $log.info("Begin execution")
      $log.success("Directories are setup")
      $log.success("Connected to database")
      $log.info("params are : #{options.list}")
    end

    def run
      begin

      report_data = ReportData.new
      report_data.start_time = Time.now
      report_data.engine_version = VERSION
      report_data.options = @options.list

      ### Create publications based on index.xml + Parse zip code of publications for entities
      ### that are not in the local database

      days_back = @options.days_back || 0

      date_object = DateRetriever.new(days_back: days_back)
      date_directory = date_object.directory_name_format
      target_date = date_object.date
      report_data.target_date = target_date

      # Abort processing if DB already contains publications for the target date
      check_not_already_exist!(target_date)

      # Create new logger with date field
      $log = $log.copy(target_day: target_date)

      # Clean working directories - varies if processing local files or png present
      unless @options.png_present?
        FileUtils.rm(Dir.glob(File.join(PATH_TO[:png], "*.png")))
        $log.success("PNG directory cleaned")
      end

      unless @options.process_local_files?
        FileUtils.rm(Dir.glob(File.join(PATH_TO[:zip], "*.zip")))
        $log.success("Zipped PDFs directory cleaned")

        FileUtils.rm(Dir.glob(File.join(PATH_TO[:unzipped], "*.pdf")))
        $log.success("Unzipped PDFs directory cleaned")
      end

      ## Download and decompress zip archive, unless processing local files option is set
      unless @options.process_local_files? || @options.png_present?
        $log.info("Creating url to download...")

        url = UriBuilder.new(date: target_date).build
        report_data.url = url
        $log.success("URL successfully created:")
        $log.info(url)

        $log.info("Downloading archive...")
        Downloader.download!(url: url, download_path: PATH_TO[:zip])
        $log.success("Download completed")


        $log.info("Unzipping files...")

        Zip.on_exists_proc = true # Configure RubyZip to allow rewriting existing xml file

        Zip::File.open(File.join(PATH_TO[:zip], Downloader::DOWNLOAD_FILE_NAME)) do |zip_file|
          zip_file.each do |entry|
            case File.extname(entry.name)
            when ".pdf" then entry.extract(destination_directory: PATH_TO[:unzipped])
            when ".xml" then entry.extract("#{date_directory}.xml", destination_directory: PATH_TO[:index])
            else
              raise Error, "Unzipping failed, file #{entry.name} not expected"
            end
          end
        end
        $log.success("Files successfully unzipped")
      end

      # Generate Publication objects from the index.xml.file :
      # - create the publications with entity_name, file_name and cbe_number (from xml)
      # - flag known and unknown publications by checking if present in enterprises table
      # - add zip code and 'probably_new=false' flag to publications of entities present
      #   in the enterprises table
      # - guess the cbe number prefix of new entities
      # - flag the publications relative to new entities with 'probably_new'
      # - retrieve the file path of unknown publications
      # - set temporary zip_code_id to 1 (unknown) to unknown publications
      #   (needed if user is not interested in zip codes, because this field
      #   has a not null constraint)

      $log.info("Generate publications data from index.xml file and checking against DB")

      xml_path = File.join(PATH_TO[:index], "#{date_directory}.xml")

      pub_factory = PublicationFactory.new(xml_path: xml_path, pub_date: date_directory)
      pub_factory.generate_publications_data
      unknown_count = pub_factory.unknown_publications.size

      $log.success("Publications data generated")

      report_data.total_known = pub_factory.known_publications.size
      report_data.total_unknown = unknown_count
      report_data.total_new = pub_factory.probably_new_count
      report_data.total_files = pub_factory.publications.size

      unless @options.skip_zipcodes?

        unless @options.png_present?
          # Create PNG files to allow OCR parsing, and store them in the PNG directory
          PNGConvertor.convert!(files: pub_factory.unknown_publications_file_paths,
            destination: PATH_TO[:png])
        end

        $log.info("Start parsing files for zip code")

        parser_results = []
        ocr_scans = []

        Dir["data/png/*.png"].each_with_index do |png_file_path, index|

          $log.info("Parsing file #{File.basename(png_file_path)}",
            file_number: index + 1,
            total_files: unknown_count)

          ocr_scan = RTesseract.new(png_file_path, lang: "fra+nld", psm: 6).to_s

          zip_code = ZipCodeEngine.retrieve_zip_code_from(ocr_scan)

          pdf_file_name = File.basename(png_file_path).sub("png", "pdf")

          parser_results << ParserResult.new(pdf_file_name, zip_code)

          ocr_file_name = File.basename(png_file_path).sub("png", "txt")
          ocr_scans << OCRScans.new(ocr_file_name, ocr_scan)

          if zip_code == "0000"
            $log.warn("Invalid zip code", file: pdf_file_name)
          else
            $log.success("Zip code = #{zip_code}", file: pdf_file_name)
          end

        end

        $log.success("Parsing finished")

        #### Assign zip codes to unknown entities
        $log.info("Updating unknown entities with zip_code")

        pub_factory.add_zip_id_to_unknown_publications(parser_results)
        report_data.zip_code_errors = pub_factory.count_zip_code_errors

        $log.success("Unknown entities updated with zip code info and complete flag")
        $log.success("Processing completed !")

        ### Store OCR text files in the App public directory under the target date directory, 'ocr'

        ocr_destination_dir = File.join(PATH_TO[:app_public_folder], date_directory, "ocr")
        $log.info("Storing OCR scans text files in #{ocr_destination_dir}...")

        FileUtils.mkdir_p(ocr_destination_dir)

        ocr_scans.each do |ocr_scan|
          File.write(File.join(ocr_destination_dir, ocr_scan.file_name), ocr_scan.scan)
        end

        report_data.ocr_scans_saved = true
        $log.success("OCR scans stored successfully")


        ### Store PNG's files in the App public directory under the target date directory, 'png'

        pngs_destination_dir = File.join(PATH_TO[:app_public_folder], date_directory, "png")
        $log.info("Storing PNG's files in #{pngs_destination_dir} directory...")

        FileUtils.mkdir_p(pngs_destination_dir)

        Dir.glob(File.join(PATH_TO[:png], "*.png")).each do |file|
          FileUtils.cp(File.expand_path(file, __FILE__),
            File.join(pngs_destination_dir, File.basename(file)))
        end

        report_data.pngs_saved = true

        $log.success("PNG files successfully stored")
      end


      if @options.skip_zipcodes?
        report_data.ocr_scans_saved = false
        report_data.pngs_saved = false
      end

      ### Store publications pdfs in the App public directory, under the target date directory, 'pdf'

      publications_destination_dir = File.join(PATH_TO[:app_public_folder], date_directory, "pdf")
      $log.info("Storing publications in #{publications_destination_dir} directory...")

      FileUtils.mkdir_p(publications_destination_dir)

      Dir.glob(File.join(PATH_TO[:unzipped], "*")).each do |file|
        FileUtils.cp(File.expand_path(file, __FILE__),
          File.join(publications_destination_dir, File.basename(file)))
      end

      report_data.publications_saved = true

      $log.success("Publications files successfully stored")

      ### Store publications in database

      $log.info("Storing publications in database...")

      DB.transaction do
        pub_factory.publications.each do |pub|
          params = {}

          params[:zip_code_id] = pub.zip_code_id
          params[:file_name] = pub.file_name
          params[:entity_name] = pub.entity_name
          params[:cbe_number] = pub.cbe_number
          params[:pub_date] = pub.pub_date
          params[:probably_new] = pub.probably_new
          params[:known] = pub.known

          # Useful for debugging
          begin
            Publication.create(params)
          rescue => e
            $log.error("Could not perform storage in database, got following error:")
            $log.error(e.message)
            $log.error("params are: #{params}")
            puts params
            puts e.message
            raise e
          end
        end
      end

      $log.success("Publications stored in the database")
      report_data.db_storage = true

      ### ReportMaker

      report_data.end_time = Time.now
      report_data.elapsed_time = report_data.end_time - report_data.start_time

      Reporter.create_report(report_data, PATH_TO[:reports], date_directory)

    ########## EXITING PROGRAM #####################################################

    rescue => e
      $log.fatal("error", e)
      raise e
    ensure
      $log.info("Exiting program")
      Dir.chdir(@origin_directory)
      DB.disconnect
      $log.success("All Exit operations performed successfully")
      @log_file.close
    end
    end

    private

    def check_not_already_exist!(target_date)
      unless Publication.where(pub_date: Date.parse(target_date)).empty?
        err_msg = "Target date #{target_date} is already present in DB. Aborting."
        $log.fatal(err_msg)
        raise Error, err_msg
      end
    end
    def config_logger
      current_date = Time.now.strftime("%Y%m%d")
      log_file_path = File.join(PATH_TO[:logs], "log_#{current_date}.log")
      @log_file = File.open(log_file_path, "a")

      $log = TTY::Logger.new(fields: @options.list) do |conf|
        conf.output = [$stderr, @log_file]
        conf.metadata = %i[date time]
        conf.level = @options.debug_mode? ? :debug : :info
      end
    end

    def setup_directories!
      PATH_TO.values { |path| FileUtils.mkdir_p(path) }
    end
  end
end
