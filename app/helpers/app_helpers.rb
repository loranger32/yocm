module Yocm
  module AppHelpers

    CBE_DATA_PATH = "yocm/data/cbe"
    CBE_METADATA_PATH = "yocm/data/cbe/meta.csv"

    CbeTable = Struct.new("CbeTable", :name, :num_records)

    def format_cbe_number(number)
      formatted_number = case number
      when /\A[10]\d{3}\.\d{3}\.\d{3}\z/ then number
      when /\A[10]\d{9}\z/ then number[0..3] + "." + number[4..6] + "." + number[7..9]
      when /\A\d{9}\z/ then "0" + number[0..2] + "." + number[3..5] + "." + number[6..8]
      else
        nil
      end

      formatted_number
    end

    def format_merge_report(report)
      added = report[:enterprises_added]
      dropped = report[:publications_dropped]
      enterprises = added > 1 ? "enterprises" : "enterprise"
      publications = dropped > 1 ? "publications" : "publication"

      "#{added} #{enterprises} merged from #{dropped} #{publications}"
    end

    def link_ocr_text(publication)
      "#{publication.pub_date.to_s.delete("-")}/ocr/#{publication.file_name.sub(".pdf", ".txt")}"
    end

    def no_data_in_cbe_folder?
      Dir[CBE_DATA_PATH, "*.csv"].empty?
    end

    def partial_cbe_number(input)
      input.delete(".").chars.each_with_object("").with_index do |(num, res), idx|
        res << "." if [4, 7].include?(idx)
        res << num
      end
    end

    def retreive_csv_files_name
      Dir[File.join(CBE_DATA_PATH, "*.csv")].map { File.basename(_1) }
    end

    # TODO - Use CbeMetadata instead
    def retrieve_csv_metadata
      result = {}
      File.open(CBE_METADATA_PATH) do |f|
        metadata = CSV.parse(f)
        result[:snapshot_date] = metadata[1][1]
        result[:extract_time_stamp] = metadata[2][1]
        result[:extract_type] = metadata[3][1]
        result[:extract_number] = metadata[4][1]
        result[:version] = metadata[5][1]
      end
      result
    end

    def retrieve_enterprise_or_publication(cbe_number)
      if (enterprise = Enterprise[cbe_number])
        return [enterprise, nil]
      elsif (publication = Publication.where(cbe_number: cbe_number).first)
        return [nil, publication]
      else
        return [nil, nil]
      end
    end

    def retrieve_regexp(ocr_text)
      case ocr_text
      when ZipCodeEngine::FRENCH_DETECTION then ZipCodeEngine::FRENCH_PARSER
      when ZipCodeEngine::DUTCH_DETECTION then ZipCodeEngine::DUTCH_PARSER
      when ZipCodeEngine::GERMAN_DETECTION then ZipCodeEngine::GERMAN_PARSER
      else
        "No matching regexp found"
      end
    end

    def sort_publications(publications_ds, sort_param, order)
      publications = case sort_param
                     when "entity_name"  then publications_ds.order_by(:entity_name)
                     when "file_name"    then publications_ds.order_by(:file_name)
                     when "cbe_number"   then publications_ds.order_by(:cbe_number)
                     when "zip_code"     then publications_ds.order_by(:zip_code_id)
                     when "complete"     then publications_ds.order_by(:zip_code_id)
                     when "probably_new" then publications_ds.order_by(:probably_new)
                     else
                       publications_ds.order_by(:file_name)
                     end

      order == "desc" ? publications.all.reverse : publications.all
    end

    def valid_cbe_number?(cbe_number)
      cbe_number.match?(/\A[1|0]\d{3}\.\d{3}\.\d{3}\z/)
    end

    def valid_pub_date?(pub_date)
      pub_date.match?(/\A\d{4}-\d{2}-\d{2}\z/i) && Publication.where(pub_date: pub_date).any?
    end

    def valid_zip_code?(zip_code)
      zip_code_found?(zip_code) && zip_code_exists?(zip_code)
    end

    private

    def zip_code_found?(zip_code)
      zip_code&.match?(/\A\d{4}\z/)
    end

    def zip_code_exists?(zip_code)
      !ZipCode.where(code: zip_code).first.nil?
    end
  end
end
