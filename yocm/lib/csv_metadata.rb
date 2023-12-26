module Yocm
  class CSVMetaData

    class NoCSVMetadataFileError < ArgumentError; end

    attr_reader :extract_number, :extract_timestamp, :format_version, :snapshot_date, :type

    def initialize(file = METADATA_FILE)
      @file = file
    end

    def parse!
      raise NoCSVMetadataFileError, "#{@file} does not exist on disk" unless File.exist?(@file)
      parse
    end

    def parse
      return unless File.exist?(@file)

      csv = File.read(@file)
      rows = CSV.parse(csv)
      @snapshot_date      = rows[1][1]
      @extract_timestamp  = rows[2][1]
      @type               = rows[3][1]
      @extract_number     = rows[4][1]
      @format_version     = rows[5][1]
      self
    end
  end
end
