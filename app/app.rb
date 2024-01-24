module Yocm
class App < Roda

  opts[:root] = File.dirname(__FILE__)

  include AppHelpers
  include ViewHelpers

  # ZIPCODE OCR PARSING - used in publications branch
  require_relative "../yocm/lib/zip_code_engine_module"

  ### PLUGINS

  # Logging
  plugin :enhanced_logger, filter: ->(path) { path.start_with?("/assets") }, trace_missed: true

  # Security - very, very basic

  plugin :sessions, key: "_Yocm.session", secret: ENV["SESSION_SECRET"]
  plugin :route_csrf

  # Routing
  plugin :all_verbs
  plugin :request_headers
  plugin :hash_routes
  Dir[File.join(opts[:root], "routes", "*.rb")].each { require_relative _1 }

  plugin :status_handler

  status_handler(404) do
    view "error_pages/404_error"
  end

  status_handler(500) do
    view "error_pages/500_error"
  end

  # Rendering
  plugin :json
  plugin :render,
    engine: "haml",
    template_opts: {escape_html: true,
                    escape_filter_interpolations: false} # needed for inline JS
  plugin :render_each
  plugin :flash
  plugin :partials
  plugin :content_for
  plugin :assets,
    css: %w[bootstrap_5_2_3.min.css style.css],
    js: {bootstrap: "bootstrap_5_2_3.bundle.min.js", main: "main.js",
         user: "user.js", edit_user: "edit_user.js",
         bs_tooltips: "bs_tooltips.js", htmx: "htmx-1-9-6.min.js", delete_pubs: "delete_pubs.js"},
    group_subdirs: false,
    timestamp_paths: true
  plugin :public

  # Request / response
  plugin :typecast_params
  alias_method :tp, :typecast_params

  route do |r|
    r.assets
    r.public
    #check_csrf!
    @active_user = User[r.session["active_user_id"]]

    r.hash_branches

    # Home page displays last processed day statistics or a welcome page if no publications yet
    r.root do
      @no_pub = Publication.count == 0

      @last_pub_date = Publication.last_pub_date
      @last_pub_count = Publication.count_all_from_date(@last_pub_date)
      @last_pub_complete_count = Publication.count_complete_from_date(@last_pub_date)
      @last_pub_probably_new_count = Publication.count_probably_new_from_date(@last_pub_date)
      @last_pub_zip_code_missing = Publication.count_zip_errors_from_date(@last_pub_date)

      view "home"
    end

    r.is "about" do
      about_text = File.read("README.md")
      @html = Kramdown::Document.new(about_text).to_html

      view "about"
    end
  end
end
end
