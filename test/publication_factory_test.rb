# frozen_string_literal: true

require_relative "test_helpers"
require_relative "../yocm/lib/publication_factory_class"
require_relative "../yocm/lib/data_handler"
require_relative "../yocm/lib/cbe_data_handler"
require_relative "../yocm/lib/zip_code_data_handler"

require "nokogiri"

PublicationFactory = Yocm::PublicationFactory

class PublicationFactoryTest < HookedTestClass
  TEST_XML_INDEX_PATH = File.expand_path("test_data/index/test_index.xml", __dir__)
  PUB_DATE = "20220128"

  def before_all
    super
    capture_io { Yocm::ZipCodeDataHandler.new(db: DB).import }
    capture_io { Yocm::CBEDataHandler.new(db: DB).import }
  end

  def around
    DB.transaction(rollback: :always, savepoint: true, auto_savepoint: true) do
      super
    end
  end

  def around_all
    DB.transaction(:rollback=>:always) do
      super
    end
  end

  def test_create_publications
    pf = PublicationFactory.new(xml_path: TEST_XML_INDEX_PATH, pub_date: PUB_DATE)
    pf.create_publications

    assert_equal 9, pf.publications.size
    assert pf.publications.all? { _1.pub_date == Date.parse(PUB_DATE) }
    assert_equal "ASBL 1", pf.publications[0].entity_name
    assert_equal "21234567.pdf", pf.publications[1].file_name
    assert_equal "0333.333.333", pf.publications[2].cbe_number
  end

  def test_flag_known_and_unknown_publications
    pf = PublicationFactory.new(xml_path: TEST_XML_INDEX_PATH, pub_date: PUB_DATE)
    pf.create_publications

    pf.flag_known_and_unknown_publications

    assert_equal 6, pf.known_publications.size
    assert_equal 3, pf.unknown_publications.size
    assert_equal "Unknown 1", pf.unknown_publications[0].entity_name
    assert_equal "Unknown 2", pf.unknown_publications[1].entity_name
    assert_equal "Unknown 3", pf.unknown_publications[2].entity_name
    assert_equal "ASBL 1", pf.known_publications[0].entity_name
    assert_equal "VZW 2", pf.known_publications[1].entity_name
    assert_equal "SRL 1", pf.known_publications[2].entity_name
    assert_equal "BV 2", pf.known_publications[3].entity_name
    assert_equal "Commune 1", pf.known_publications[4].entity_name
    assert_equal "Gemeente 2", pf.known_publications[5].entity_name
  end

  def test_publications_accessor_methods_raises_if_publications_is_empty
    pf = PublicationFactory.new(xml_path: TEST_XML_INDEX_PATH, pub_date: PUB_DATE)
    assert_raises(Yocm::PublicationFactory::Error) { pf.known_publications }
    assert_raises(Yocm::PublicationFactory::Error) { pf.unknown_publications }
    assert_raises(Yocm::PublicationFactory::Error) { pf.probably_new_count }
    assert_raises(Yocm::PublicationFactory::Error) { pf.flag_known_and_unknown_publications }
    assert_raises(Yocm::PublicationFactory::Error) do
      pf.add_zip_id_to_unknown_publications(nil)
    end
    assert_raises(Yocm::PublicationFactory::Error) do
      pf.set_temporary_zip_code_id_1_to_unknown_publications
    end
  end

  def test_unknown_publications_file_pathes_raises_if_file_pathes_not_retrieved_yet
    pf = PublicationFactory.new(xml_path: TEST_XML_INDEX_PATH, pub_date: PUB_DATE)
    pf.create_publications
    pf.flag_known_and_unknown_publications
    pf.add_zip_and_probably_not_new_flag_to_known_publications
    pf.find_new_entity_prefix
    pf.flag_probably_new_publications

    assert_raises(Yocm::PublicationFactory::Error) { pf.unknown_publications_file_paths }
  end

  def test_add_zip_and_probably_not_new_flag_to_known_publications
    pf = PublicationFactory.new(xml_path: TEST_XML_INDEX_PATH, pub_date: PUB_DATE)
    pf.create_publications
    pf.flag_known_and_unknown_publications

    pf.add_zip_and_probably_not_new_flag_to_known_publications

    assert pf.known_publications.none?(&:probably_new)
    assert pf.unknown_publications.all? { _1.probably_new.nil? }

    assert_equal 2, pf.known_publications[0].zip_code_id
    assert_equal 269, pf.known_publications[1].zip_code_id
    assert_equal 429, pf.known_publications[2].zip_code_id
    assert_equal 776, pf.known_publications[3].zip_code_id
    assert_equal 1145, pf.known_publications[4].zip_code_id
    assert_equal 1518, pf.known_publications[5].zip_code_id

    assert_nil pf.unknown_publications[0].zip_code_id
    assert_nil pf.unknown_publications[1].zip_code_id
  end

  def test_find_new_entity_prefix
    pf = PublicationFactory.new(xml_path: TEST_XML_INDEX_PATH, pub_date: PUB_DATE)
    pf.create_publications
    pf.flag_known_and_unknown_publications
    pf.add_zip_and_probably_not_new_flag_to_known_publications

    pf.find_new_entity_prefix

    assert_equal "0777", pf.instance_variable_get(:@probably_new_prefix)
  end

  def test_flag_probably_new_publications
    pf = PublicationFactory.new(xml_path: TEST_XML_INDEX_PATH, pub_date: PUB_DATE)
    pf.create_publications
    pf.flag_known_and_unknown_publications
    pf.add_zip_and_probably_not_new_flag_to_known_publications
    pf.find_new_entity_prefix

    pf.flag_probably_new_publications

    assert_equal 2, pf.probably_new_count
    refute pf.unknown_publications.all?(&:probably_new)
    refute pf.publications.select(&:probably_new).any? { _1.entity_name == "Unknown 3" }
    probably_new = pf.publications.select(&:probably_new)
    assert_equal "Unknown 1", probably_new[0].entity_name
    assert_equal "Unknown 2", probably_new[1].entity_name
  end

  def test_retrieve_unknown_publications_file_pathes
    pf = PublicationFactory.new(xml_path: TEST_XML_INDEX_PATH, pub_date: PUB_DATE)
    pf.create_publications
    pf.flag_known_and_unknown_publications
    pf.add_zip_and_probably_not_new_flag_to_known_publications
    pf.find_new_entity_prefix
    pf.flag_probably_new_publications

    pf.retrieve_unknown_publications_file_paths

    assert_equal File.join(Yocm::Engine::PATH_TO[:unzipped], "71234567.pdf"), pf.unknown_publications_file_paths[0]
    assert_equal File.join(Yocm::Engine::PATH_TO[:unzipped], "81234567.pdf"), pf.unknown_publications_file_paths[1]
    assert_equal File.join(Yocm::Engine::PATH_TO[:unzipped], "91234567.pdf"), pf.unknown_publications_file_paths[2]
  end

  def test_set_temporary_zip_code_id_1_to_unknown_publications
    pf = PublicationFactory.new(xml_path: TEST_XML_INDEX_PATH, pub_date: PUB_DATE)
    pf.create_publications
    pf.flag_known_and_unknown_publications
    pf.add_zip_and_probably_not_new_flag_to_known_publications
    pf.find_new_entity_prefix
    pf.flag_probably_new_publications
    pf.retrieve_unknown_publications_file_paths

    pf.set_temporary_zip_code_id_1_to_unknown_publications

    assert pf.unknown_publications.all? { _1.zip_code_id == 1 }
    assert pf.unknown_publications.none?(&:complete?)
  end

  def test_generate_publications
    pf = PublicationFactory.new(xml_path: TEST_XML_INDEX_PATH, pub_date: PUB_DATE)
    pf.generate_publications_data

    assert_equal 9, pf.publications.size
    assert pf.publications.all? { _1.pub_date == Date.parse(PUB_DATE) }

    assert_equal 6, pf.known_publications.size
    assert_equal 3, pf.unknown_publications.size
    assert_equal "Unknown 1", pf.unknown_publications[0].entity_name
    assert_equal "Unknown 2", pf.unknown_publications[1].entity_name
    assert_equal "Unknown 3", pf.unknown_publications[2].entity_name
    assert_equal "ASBL 1", pf.known_publications[0].entity_name
    assert_equal "VZW 2", pf.known_publications[1].entity_name
    assert_equal "SRL 1", pf.known_publications[2].entity_name
    assert_equal "BV 2", pf.known_publications[3].entity_name
    assert_equal "Commune 1", pf.known_publications[4].entity_name
    assert_equal "Gemeente 2", pf.known_publications[5].entity_name

    assert_equal "Unknown 1", pf.unknown_publications[0].entity_name
    assert_equal "Unknown 2", pf.unknown_publications[1].entity_name
    assert_equal "Unknown 3", pf.unknown_publications[2].entity_name

    assert pf.known_publications.all?(&:complete?)
    assert pf.unknown_publications.all? { _1.complete? == false } # Explicitly check false

    assert_equal 2, pf.known_publications[0].zip_code_id
    assert_equal 269, pf.known_publications[1].zip_code_id
    assert_equal 429, pf.known_publications[2].zip_code_id
    assert_equal 776, pf.known_publications[3].zip_code_id
    assert_equal 1145, pf.known_publications[4].zip_code_id
    assert_equal 1518, pf.known_publications[5].zip_code_id

    assert_equal 1, pf.unknown_publications[0].zip_code_id
    assert_equal 1, pf.unknown_publications[1].zip_code_id
    assert_equal 1, pf.unknown_publications[2].zip_code_id

    assert_equal 2, pf.probably_new_count
    refute pf.unknown_publications.all?(&:probably_new)
    refute pf.publications.select(&:probably_new).any? { _1.entity_name == "Unknown 3" }
    probably_new = pf.publications.select(&:probably_new)
    assert_equal "Unknown 1", probably_new[0].entity_name
    assert_equal "Unknown 2", probably_new[1].entity_name

    assert_equal 3, pf.unknown_publications_file_paths.size
    assert_equal File.join(Yocm::Engine::PATH_TO[:unzipped], "71234567.pdf"), pf.unknown_publications_file_paths[0]
    assert_equal File.join(Yocm::Engine::PATH_TO[:unzipped], "81234567.pdf"), pf.unknown_publications_file_paths[1]
    assert_equal File.join(Yocm::Engine::PATH_TO[:unzipped], "91234567.pdf"), pf.unknown_publications_file_paths[2]
    assert_equal "0777", pf.instance_variable_get(:@probably_new_prefix)
  end

  def test_add_zip_and_complete_flag_to_unknown_publications
    parser_result = Struct.new(:file_name, :zip_code)
    parsing_results = [parser_result.new("71234567.pdf", "1000"),
      parser_result.new("81234567.pdf", "0000"),
      parser_result.new("91234567.pdf", "9999")]

    pf = PublicationFactory.new(xml_path: TEST_XML_INDEX_PATH, pub_date: PUB_DATE)
    pf.generate_publications_data

    pf.add_zip_id_to_unknown_publications(parsing_results)

    assert_equal 1, pf.unknown_publications.count(&:complete?)
    assert_equal 2, pf.unknown_publications.select(&:complete?).first.zip_code_id

    assert_equal 2, pf.unknown_publications.reject(&:complete?).size
    assert pf.unknown_publications.reject(&:complete?).all? { _1.zip_code_id == 1 }
  end
end
