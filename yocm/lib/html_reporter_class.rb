require "erb"

module Yocm
  class HTMLReporter
    TEMPLATE_PATH = File.expand_path("../templates/execution_report.erb", __dir__)

    class << self
      def create_report(data, path, date)
        new(data, path, date).create_report
      end
    end

    def initialize(data, path, date)
      @data = data
      @path = path
      @date = date
    end

    def create_report
      $log.info("Start creating report...")

      template = File.read(TEMPLATE_PATH)

      erb = ERB.new(template).result(binding)

      @execution_report_path = File.join(@path, "report_#{@date}.html")

      File.write(@execution_report_path, erb)

      $log.info("Report successfully created in #{@execution_report_path}")
    end
  end
end
