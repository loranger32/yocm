# frozen_string_literal: true

require_relative "test_helpers"
require_relative "../yocm/lib/cbe_data_handler"
require_relative "../yocm/lib/zip_code_data_handler"

class ModelsTest < HookedTestClass
  def before_all
    @all_models = [Address, CbeMetadata, Denomination, Enterprise, Establishment, User, ZipCode]
    assert @all_models.all?(&:empty?)

    capture_io { Yocm::ZipCodeDataHandler.new(db: DB).import }
    capture_io { Yocm::CBEDataHandler.new(db: DB).import }
    DB[:users].insert(email: "test_user@example.com")
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

  def after_all
    @all_models.each { _1.all(&:delete) unless _1.empty? }
  end

  def test_address_has_required_accessors
    address = Address["0111.111.111"]
    refute_nil address
    refute_nil address.id
    assert_equal "REGO", address.type_of_address
    assert_nil address.country_nl
    assert_nil address.country_fr
    assert_equal "1000", address.zip_code
    assert_equal "Brussel", address.municipality_nl
    assert_equal "Bruxelles", address.municipality_fr
    assert_equal "Brusselsestraat", address.street_nl
    assert_equal "Rue de Bruxelles", address.street_fr
    assert_equal "1", address.house_number
    assert_equal "23", address.box
    assert_nil address.extra_address_info
    assert_nil address.date_striking_of
  end

  def test_address_has_required_associations
    # Test with a belgian entity with no succursale

    enterprise1 = Enterprise["0111.111.111"]
    unique_address = Address["0111.111.111"]

    assert_equal enterprise1, unique_address.enterprise
    assert_nil unique_address.establishment

    # Test with a belgian entity with many succursale

    enterprise2 = Enterprise["0666.666.666"]
    address_of_hq = enterprise2.address
    assert_equal enterprise2, Address["0666.666.666"].enterprise
    assert_nil address_of_hq.establishment

    sucursale_one = Establishment["2.666.666.662"]
    assert_equal sucursale_one, Address["2.666.666.662"].establishment

    # Test with a foreign entity
    DB[:enterprises].insert(id: "0111.000.000", juridical_situation: "000",
      type_of_enterprise: "2", juridical_form_id: "030", juridical_form_cac_id: "030", 
      start_date: "01-01-2020")
    DB[:establishments].insert(id: "2.111.000.001", start_date: "01-01-2001", enterprise_id: "0111.000.000")
    DB[:addresses].insert(id: "0111.000.000", type_of_address: "REGO",
      country_nl: "Foreign Country", country_fr: "Foreign Country", zip_code: "25B-2569")
    DB[:addresses].insert(id: "2.111.000.001", type_of_address: "BAET",
      country_nl: nil, country_fr: nil, zip_code: "1000")

    enterprise3 = Enterprise["0111.000.000"]
    foreign_address_of_hq = Address["0111.000.000"]
    belgian_address = Address["2.111.000.001"]
    assert_equal enterprise3, foreign_address_of_hq.enterprise
    assert_equal enterprise3, belgian_address.enterprise

    assert_nil foreign_address_of_hq.establishment
    assert_equal Establishment["2.111.000.001"], belgian_address.establishment
  end

  def test_branch_has_required_accessors
    branch = Branch["9.111.333.333"]
    assert_equal "9.111.333.333", branch.id
    assert_equal Date.parse("01-01-2013"), branch.start_date
    assert_equal "0111.333.333", branch.enterprise_id
  end

  def test_branch_as_required_associations
    assert_equal Enterprise["0111.333.333"], Branch["9.111.333.333"].enterprise
    assert_equal Address["9.111.333.333"], Branch["9.111.333.333"].address
  end

  def test_cbe_metadata_has_the_required_accessors
    cbe_metadata = CbeMetadata.where(extract_number: 3).first
    refute_nil cbe_metadata
    assert_equal Date.parse("31-01-2022"), cbe_metadata.snapshot_date
    assert_equal Time.parse("05-02-2022 17:14:10"), cbe_metadata.extract_time_stamp
    assert_equal "full", cbe_metadata.extract_type
    assert_equal "1.0.0", cbe_metadata.version
  end

  def test_denominations_has_required_accessors_and_associations
    denomination = Denomination.where(enterprise_id: "0222.222.222").first
    refute_nil denomination
    refute_nil denomination.id
    assert_equal "2", denomination.language
    assert_equal "001", denomination.type_of_denomination
    assert_equal "VZW 2", denomination.description

    enterprise = Enterprise["0222.222.222"]
    assert_equal enterprise, denomination.enterprise
  end

  def test_enterprise_has_required_accessors_and_associations
    enterprise = Enterprise[id: "0333.333.333"]
    refute_nil enterprise
    assert_equal "000", enterprise.juridical_situation
    assert_equal "2", enterprise.type_of_enterprise
    assert_equal "610", enterprise.juridical_form_id
    assert_equal "Société à responsabilité limitée", enterprise.juridical_form
    assert_equal "Société à responsabilité limitée", enterprise.juridical_form("FR")
    assert_equal "Besloten Vennootschap", enterprise.juridical_form("NL")
    assert_equal "Gesellschaft mit beschränkter Haftung", enterprise.juridical_form("DE")
    assert_equal "610", enterprise.juridical_form_cac_id
    assert_equal Date.parse("01-01-2003"), enterprise.start_date

    assert_equal Address["0333.333.333"], enterprise.address
    assert_equal Address["0333.333.333"], enterprise.belgian_address

    enterprise_main_denomination = Denomination.where(enterprise_id: "0333.333.333").first
    assert_equal enterprise_main_denomination, enterprise.denominations.first
    assert_equal "SRL 1", enterprise.name

    assert enterprise.has_establishment?
    refute enterprise.has_branch?
    enterprise_main_establishment = Establishment.where(enterprise_id: "0333.333.333").first
    assert_equal enterprise_main_establishment, enterprise.establishments.first

    foreign_enterprise_with_branch = Enterprise["0111.333.333"]
    assert foreign_enterprise_with_branch.has_branch?
    refute foreign_enterprise_with_branch.has_establishment?
    assert_equal Branch["9.111.333.333"], foreign_enterprise_with_branch.branch
  end

  def test_enterprise_belgian_zip_code_id_returns_belgian_zip_code
    enterprise = Enterprise["0444.444.444"]
    assert_equal 776, enterprise.belgian_zip_code_id # 776 is 4000 Liège / Luik
  end

  def test_enterprise_belgian_zip_code_id_returns_belgian_establishment_zip_code_id_if_one
    enterprise = Enterprise["0111.222.222"]
    assert enterprise.has_establishment?
    assert_equal 2, enterprise.belgian_zip_code_id # ==  1000 Brussels
  end

  def test_enterprise_belgian_zip_code_id_returns_belgian_branch_zip_code__id_if_one
    enterprise = Enterprise["0111.333.333"]
    assert enterprise.has_branch?
    assert_equal 429, enterprise.belgian_zip_code_id # == 3000 Leuven
  end

  def test_enterprise_belgian_zip_code_id_returns_unknown_zop_code_id_if_no_belgian_address
    enterprise_with_no_belgian_address =  Enterprise["0111.333.333"]
    Address["9.111.333.333"].delete
    Branch["9.111.333.333"].delete
    
    assert_equal 1, enterprise_with_no_belgian_address.belgian_zip_code_id 
  end

  def test_enterprise_can_return_both_foreign_and_belgian_address
    enterprise_with_establishment = Enterprise["0111.222.222"]
    assert_equal Address["0111.222.222"], enterprise_with_establishment.address
    assert_equal Address["2.111.222.223"], enterprise_with_establishment.belgian_address

    enterprise_with_branch = Enterprise["0111.333.333"]
    assert_equal Address["0111.333.333"], enterprise_with_branch.address
    assert_equal Address["9.111.333.333"], enterprise_with_branch.belgian_address
  end

  def test_enterprise_returns_foreign_address_if_no_belgian_address_available
    Address["9.111.333.333"].delete
    enterprise_with_no_belgian_address = Enterprise["0111.333.333"]
    assert_equal Address["0111.333.333"], enterprise_with_no_belgian_address.address
  end

  def test_enterprise_convenience_methods
    enterprise = Enterprise["0111.111.111"]
    assert enterprise.belgian_box?
    assert_equal "23", enterprise.belgian_box
    assert_equal "Rue de Bruxelles 1", enterprise.belgian_street_and_number
    assert_equal "1000 Bruxelles", enterprise.belgian_zip_and_city

    assert enterprise.box?
    assert_equal "23", enterprise.box
    assert_equal "Rue de Bruxelles 1", enterprise.street_and_number
    assert_equal "1000 Bruxelles", enterprise.zip_and_city
  
    assert enterprise.company?
    assert_equal "Belgique", enterprise.country_fr
    assert_equal "België", enterprise.country_nl
    assert_equal "Belgique / België", enterprise.country_fr_and_nl

    refute enterprise.foreign_entity?
  end

  def test_establishment_has_required_accessors_and_associations
    establishment = Establishment["2.666.666.661"]
    assert_equal "2.666.666.661", establishment.id
    assert_equal Date.parse("01-01-2006"), establishment.start_date
    assert_equal "0666.666.666", establishment.enterprise_id
    assert_equal Enterprise["0666.666.666"], establishment.enterprise
  end

  def test_publication_has_required_accessors
    # Needs to be extended
    pub = Publication.new
    assert_respond_to pub, :id
    assert_respond_to pub, :file_name
    assert_respond_to pub, :cbe_number
    assert_respond_to pub, :pub_date
    assert_respond_to pub, :complete?
    assert_respond_to pub, :zip_code_id
    assert_respond_to pub, :zip_code
    assert_respond_to pub, :probably_new
    assert_respond_to pub, :entity_name
    assert_respond_to pub, :known
  end

  def test_users_has_required_accessors_and_association
    user = User.where(email: "test_user@example.com").first
    refute_nil user
    user.add_zip_code(ZipCode[2])
    assert_equal "Bruxelles", user.zip_codes.first.village_fr

    enterprise = Enterprise.first
    user.add_enterprise(enterprise)
    assert_equal "0111.111.111", user.enterprises.first.id

    user.destroy
    refute_nil ZipCode[2]
    refute_nil enterprise
  end

  def test_zip_code_has_required_accessors_and_association_and_class_method
    zip_code = ZipCode[2] # Brussels
    refute_nil zip_code
    assert_equal "Bruxelles", zip_code.village_fr
    assert_equal "Brussel", zip_code.village_nl
    assert_equal "BRUXELLES", zip_code.city_fr
    assert_equal "BRUSSEL", zip_code.city_nl
    assert_equal "BRUXELLES", zip_code.province_fr
    assert_equal "BRUSSEL", zip_code.province_nl
    assert_respond_to zip_code, :users
    assert ZipCode.loaded?
  end
end
