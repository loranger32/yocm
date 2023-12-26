module Yocm
  class CBEWebAgent

    CBE_LOGIN_PAGE = "https://kbopub.economie.fgov.be/kbo-open-data/login".freeze
    LOGIN_FORM_ACTION = "/kbo-open-data/static/j_spring_security_check".freeze
    CBE_WEBSITE_LOGIN = ENV["CBE_WEBSITE_LOGIN"].freeze
    CBE_WEBSITE_PASSWORD = ENV["CBE_WEBSITE_PASSWORD"].freeze
    CBE_WEBSITE_DOWNLOAD_PAGE = "https://kbopub.economie.fgov.be/kbo-open-data/affiliation/xml/?files".freeze

    def initialize
      @agent = Mechanize.new
    end

    def available_data_sets
      authenticate

      @data_page = @agent.get(CBE_WEBSITE_DOWNLOAD_PAGE)

      available_data_sets = @data_page.links_with(href: /KboOpenData/)
                                      .map(&:href)
                                      .map { _1.scan(/\Afiles\/KboOpenData_\d(\d{3})/)}
                                      .flatten
                                      .uniq
    end

    private

      def authenticate
        login_page = @agent.get(CBE_LOGIN_PAGE)
        login_form = login_page.form_with(action: LOGIN_FORM_ACTION)
        login_form.j_username = CBE_WEBSITE_LOGIN
        login_form.j_password = CBE_WEBSITE_PASSWORD
        @agent.submit(login_form)
      end
  end
end
