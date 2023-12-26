module Yocm
  class DateRetriever

    class Error < StandardError; end

    def initialize(days_back:)
      check_days_back_argument(days_back)
      @target_date = retrieve_target_date(days_back)

      if @target_date.saturday? || @target_date.sunday?
        err_msg = "No publication during week-ends (target day is #{@target_date}, which is a #{@target_date.strftime("%A")}"
        $log.fatal(err_msg)
        raise Error, err_msg
      end
    end

    def date
      @target_date.strftime("%Y/%m/%d")
    end

    def directory_name_format
      @target_date.strftime("%Y%m%d")
    end

    private

      def check_days_back_argument(days_back)
        err_msg = "Expected an integer as argument, got #{days_back} of class #{days_back.class} instead"
        unless days_back.is_a?(Integer)
          $log.fatal(err_msg)
          raise Error, err_msg
        end
      end

      def retrieve_target_date(days_back)
        # Hack to allow testing during weekends :-)
        actual_time = if ENV["RUN_ENV"] == "test"
          Time.new(2022, 1, 27)
        else
          Time.now
        end

        return actual_time if days_back.zero?

        actual_time_in_seconds = actual_time.to_i
        days_back_in_seconds = days_back * 60 * 60 * 24

        target_day = actual_time_in_seconds - days_back_in_seconds

        Time.at(target_day)
      end
    end
end

