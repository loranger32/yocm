module Yocm
  class Downloader
    class Error < StandardError; end

    DOWNLOAD_FILE_NAME = "download.zip".freeze

    class << self
      def download!(url:, download_path:)
        new(url, download_path).download!
      end
    end

    def initialize(url, download_path)
      @url = url
      @download_path = download_path
    end

    def download!
      begin
        doc = URI.parse(@url).open
      rescue StandardError => e
        $log.error(e.message)
        raise e
      end
      FileUtils.cp(doc, File.join(@download_path, DOWNLOAD_FILE_NAME))
    end
  end
end

