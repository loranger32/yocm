module Yocm
  module ZipCodeEngine
    FRENCH_DETECTION = /si[éèeë]ge/i
    DUTCH_DETECTION = /ze[ftl]e[lti!]/i
    GERMAN_DETECTION = /si[lti]ze?s?/i

    FRENCH_PARSER = /[u\s+\-]si[éèeë]ge\s*:?\s*(.+)/im
    DUTCH_PARSER = /[\s+\-]ze[ftl]e[lti!]\s*:?\s*(.+)/im
    GERMAN_PARSER = /[\s+\-]si[lti]ze?s?\s*:?\s*(.+)/im

    module_function

    def retrieve_zip_code_from(ocr_scan)
      matches = scan_for_target(ocr_scan)

      if matches
        valid_zip_code_from(matches) || "0000"
      else
        "0000"
      end
    end

    def scan_for_target(text)
      case text
      when FRENCH_DETECTION then scan_fr(text)
      when DUTCH_DETECTION then scan_nl(text)
      when GERMAN_DETECTION then scan_de(text)
      end
    end

    def valid_zip_code_from(matches)
      match = matches[1].scan(/[1-9]\d{3}/)[0]
      if match.nil? || match.empty?
        nil
      else
        valid_zip_code?(match) ? match : nil
      end
    end

    def scan_fr(text)
      text.match(FRENCH_PARSER)
    end

    def scan_nl(text)
      text.match(DUTCH_PARSER)
    end

    def scan_de(text)
      text.match(GERMAN_PARSER)
    end

    def valid_zip_code?(code)
      !ZipCode.where(code: code).first.nil?
    end
  end
end
