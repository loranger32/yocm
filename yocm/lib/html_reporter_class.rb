require "erb"

module Yocm
  class HTMLReporter
    TEMPLATE_PATH = File.expand_path("../templates/html_report.erb", __dir__)

    class << self
      def create_report(data, path, date)
        new(data, path, date).create_report
      end

      def no_zip_codes_selected?(user)
        user.follow_no_zips?
      end

      def no_enterprise_selected?(user)
        user.follow_no_cbe_number?
      end
    end

    def initialize(data, path, date)
      @data = data
      @path = path
      @date = date
    end

    def create_report
      $log.info("Start creating HTML report...")

      template = File.read(TEMPLATE_PATH)

      erb = ERB.new(template).result(binding)

      @execution_report_path = File.join(@path, "report_#{@date}.html")

      File.write(@execution_report_path, erb)

      $log.info("Report successfully created in #{@execution_report_path}")
    end
  end
end
