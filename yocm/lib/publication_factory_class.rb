module Yocm
  class PublicationFactory
    class Error < StandardError; end

    attr_reader :publications

    def initialize(xml_path:, pub_date:)
      @xml = File.read(xml_path, encoding: "iso-8859-1").encode("UTF-8")
      @pub_date = pub_date
      @publications = []
      @probably_new_prefix = nil
      @unknown_publications_file_paths = []
      @all_pub_flagged = false
    end

    def add_zip_and_probably_not_new_flag_to_known_publications
      known_publications.each do |pub|


        pub.zip_code_id = Enterprise[pub.cbe_number].belgian_zip_code_id
        pub.probably_new = false
      # useful for debugging
      rescue => e
        puts "Error with a publication:\n" \
          "Entity name: #{pub.entity_name}\n" \
          "File name: #{pub.file_name}\n" \
          "Date: #{pub.pub_date}\n" \
          "CBE Number: #{pub.cbe_number}" \
          "Zip code id: #{pub.zip_code_id}" \
          "Known entity: #{pub.known}"
        raise e
      end
    end

    def add_zip_id_to_unknown_publications(parsing_results)
      unknown_publications.each do |pub|
        matching_result = parsing_results.select { |result| pub.file_name == result.file_name }.first

        # assign zip_code_id
        zip_code = ZipCode.where(code: matching_result.zip_code).first
        pub.zip_code_id = zip_code ? zip_code.id : 1
      end

      @all_pub_flagged = true
    end

    def count_zip_code_errors
      raise Error, "No publications created yet" unless @all_pub_flagged

      publications.count { _1.zip_code_id == 1 }
    end

    def create_publications
      Nokogiri::XML(@xml).xpath("//pubs//PUB").each do |data|
        entity_name = data.at_xpath("NAAM").content
        file_name = data.at_xpath("NUM").content + ".pdf"
        cbe_number = data.at_xpath("BTW").content
        formatted_cbe_number = "#{cbe_number[0..3]}.#{cbe_number[4..6]}.#{cbe_number[7..9]}"

        publications << Publication.new(entity_name: entity_name,
          file_name: file_name,
          pub_date: @pub_date,
          cbe_number: formatted_cbe_number)
      end
    end

    def find_new_entity_prefix
      cbe_numbers = unknown_publications.map(&:cbe_number)
      counted_prefixes = cbe_numbers.map { |number| number[0..3] }.tally
      most_frequent = counted_prefixes.values.max
      @probably_new_prefix = counted_prefixes.select { |_, v| v == most_frequent }.keys[0]
    end

    def flag_known_and_unknown_publications
      raise Error, "No publications created yet" if publications.empty?

      publications.each { _1.known = !Enterprise[_1.cbe_number].nil? }
    end

    def flag_probably_new_publications
      unknown_publications.each do |pub|
        pub.probably_new = pub.cbe_number.start_with?(@probably_new_prefix)
      end
    end

    def generate_publications_data
      create_publications
      flag_known_and_unknown_publications
      add_zip_and_probably_not_new_flag_to_known_publications
      find_new_entity_prefix
      flag_probably_new_publications
      retrieve_unknown_publications_file_paths
      set_temporary_zip_code_id_1_to_unknown_publications
    end

    def known_publications
      raise Error, "No publications created yet" if publications.empty?
      publications.select(&:known)
    end

    def probably_new_count
      raise Error, "No publications created yet" if publications.empty?
      publications.count(&:probably_new)
    end

    def retrieve_unknown_publications_file_paths
      unknown_publications.each do |pub|
        @unknown_publications_file_paths << File.join(Yocm::Engine::PATH_TO[:unzipped], pub.file_name)
      end
    end

    def set_temporary_zip_code_id_1_to_unknown_publications
      unknown_publications.each {_1.zip_code_id = 1 }
    end

    def unknown_publications
      raise Error, "No publications created yet" if publications.empty?
      publications.reject(&:known)
    end

    def unknown_publications_file_paths
      raise Error, "Files paths not yet collected" if @unknown_publications_file_paths.empty?
      @unknown_publications_file_paths
    end
  end
end
