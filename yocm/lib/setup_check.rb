module Yocm
  class SetupCheck

    class SetupError < StandardError; end

    Binary = Data.define(:name, :cmd)
    Lang   = Data.define(:name, :code)

    REQUIRED_BINARIES = [SQLITE3   = Binary.new("SQLite", "sqlite3"),
                         MAGICK    = Binary.new("ImageMagick", "convert"),
                         GS        = Binary.new("Ghostscript", "ghostscript"),
                         TESSERACT = Binary.new("Tesseract", "tesseract")].freeze

    REQUIRED_LANGS = [DUTCH  = Lang.new("Dutch", "nld"),
                      FRENCH = Lang.new("French", "fra"),
                      GERMAN = Lang.new("German", "deu")].freeze

    def initialize
      @binaries = gather_installed_bin
      @langs    = gather_installed_langs
    end

    def check_setup!(features = :all)
      msg = "All dependencies are not satisfied, run `ruby yocm/yocm.rb --check-setup` to diagnose"
      raise SetupError, msg unless setup_ok?(features)
    end

    def display_checks
      display_banner
      display_binaries_banner
      display_binaries_checks
      display_langs_banner
      display_langs_check
      display_recap
    end

    def setup_ok?(features = :all)
      case features
      when :all then all_binary_presents? && all_langs_present?
      when :db  then db_present?
      else
        raise SetupError, "Wrong feature flag provided, must be :all or :db, got #{features}"
      end
    end

    private

      def all_binary_presents?
        REQUIRED_BINARIES.all? { bin_present?(_1) }
      end

      def all_langs_present?
        REQUIRED_LANGS.all? { lang_present?(_1) }
      end

      def bin_present?(bin)
        @binaries.include?(bin)
      end

      def check_bin?(bin)
        system("#{bin.cmd} --version >/dev/null 2>&1")
      end

      def db_present?
        @binaries.include?(SQLITE3)
      end

      def display_banner
        puts "***************"
        puts "* SETUP CHECK *"
        puts "***************"
        puts
      end

      def display_binaries_banner
        puts "BINARIES"
        puts
      end

      def display_binaries_checks
        REQUIRED_BINARIES.each do |bin|
          print "#{bin.name}: "
          if @binaries.include?(bin)
            puts $pastel.green("yes")
          else
            puts $pastel.red("no")
          end
        end
      end

       def display_langs_banner
      puts
      puts "TESSERACT LANGUAGES MODULES"
      puts
    end

    def display_langs_check
      REQUIRED_LANGS.each do |lang|
        print "#{lang.name}: "
        if lang_present?(lang)
          puts $pastel.green("yes")
        else
          puts $pastel.red("no")
        end
      end
      puts
    end

    def display_recap
      if all_binary_presents? && all_langs_present?
        puts $pastel.green("Setup OK")
      else
        puts "Install required binaries" unless all_binary_presents?

        unless all_langs_present?
          puts "Install required languages modules:"
          REQUIRED_LANGS.each { |lang| puts "#{lang.name} (#{lang.code})" unless lang_present?(lang) }
        end

      end
    end

    def gather_installed_bin
      REQUIRED_BINARIES.each_with_object([]) { |bin, installed| installed << bin if check_bin?(bin) }
    end

    def gather_installed_langs
      langs = []
      return langs unless tesseract?

      r, io = IO.pipe

      fork do
        system("#{TESSERACT.cmd} --list-langs", out: io, err: :out)
      end

      io.close

      r.each_line do |line|
        REQUIRED_LANGS.each { |lang| langs << lang if line.chomp == lang.code }
      end
      langs
    end

    def lang_present?(lang)
      @langs.include?(lang)
    end

    def tesseract?
      @binaries.include?(TESSERACT)
    end
  end
end
