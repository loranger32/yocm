module Yocm
  class UriBuilder
    class Error < StandardError; end

    URI_PREFIX = "https://www.ejustice.just.fgov.be/tsv_pdf/"
    URI_SUFFIX = "/pdf.zip"

    def initialize(date:)
      check_date_is_a_string(date)
      check_date_is_of_valid_format(date)
      @date = date
    end

    def build
      URI_PREFIX + @date + URI_SUFFIX
    end

    private

    def check_date_is_a_string(date)
      err_msg = "UriBuilder #new argument must be a string, got #{date} of class #{date.class} instead"
      raise Error, err_msg unless date.is_a?(String)
    end

    def check_date_is_of_valid_format(date)
      err_msg = "Invalid date format, must be yyyy/mm/dd. Got #{date} instead"
      raise Error, err_msg unless date.match?(/\A\d{4}\/\d{2}\/\d{2}\z/)
    end
  end
end
