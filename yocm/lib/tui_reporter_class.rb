module Yocm
  class TUIReporter
    TEMPLATE_PATH = File.expand_path("../templates/tui_report.erb", __dir__)

    def self.tabulate_zip_code_results(results)
      results.map.with_object(String.new) { |result, table| table << "#{result.code} | #{result.num_matches} |\n" }
    end

    def self.tabulate_enterprise_results(results)
      results.map.with_object(String.new) { |result, table| table << "#{result.cbe_number} | #{result.denomination} |\n" }
    end

    def self.no_zip_codes_selected?(user)
      user.follow_no_zips?
    end

    def self.no_enterprise_selected?(user)
      user.follow_no_cbe_number?
    end

    def initialize(data)
      @data = data
    end

    def create_report
      template = File.read(TEMPLATE_PATH)

      erb = ERB.new(template).result(binding)

      @tui_markdown_report = TTY::Markdown.parse(erb)
    end

    def display_report
      @tui_markdown_report ||= create_report
      puts @tui_markdown_report
    end
  end
end
