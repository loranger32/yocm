require_relative "test_helpers"
require_relative "../yocm/lib/results_manager_class"
require_relative "../yocm/lib/data_handler"
require_relative "../yocm/lib/cbe_data_handler"
require_relative "../yocm/lib/zip_code_data_handler"

class ResultsManagerInitializeTest < HookedTestClass
  TARGET_DATE = Date.new(2024, 12, 14)

  def around_all
    DB.transaction(rollback: :always) do
      capture_io { Yocm::ZipCodeDataHandler.new(db: DB).import }
      capture_io { Yocm::CBEDataHandler.new(db: DB).import }
      User.create(email: "test_user@example.com", active: true)
      @user = User.first
      @asbl1 = Enterprise["0111.111.111"]
      @vzw2 = Enterprise["0222.222.222"]
      @srl1 = Enterprise["0333.333.333"]
      @bv2 = Enterprise["04444.444.444"]
      @commune1 = Enterprise["0555.555.555"]
      @gemeente2 = Enterprise["0666.666.666"]
      @user.add_enterprise(@asbl1)
      @user.add_enterprise(@vzw2)
      @user.add_enterprise(@srl1)
      @brussels = ZipCode[2]
      @anvers = ZipCode[269]
      @leuven = ZipCode[429]
      @liege = ZipCode[777]
      @namur = ZipCode[1146]
      @charleroi = ZipCode[1518]
      @user.add_zip_code(@leuven)
      @user.add_zip_code(@liege)
      @user.reload

      # Enterprise : followed --- Zip Code : not followed --- Date : OK
      Publication.create(file_name: "file_1.pdf", cbe_number: "0111.111.111", pub_date: TARGET_DATE,
                         zip_code_id: @brussels.id, probably_new: false, entity_name: "ASBL 1", known: true)

      # Enterprise : followed --- Zip Code : not followed --- Date : OK
      Publication.create(file_name: "file_2.pdf", cbe_number: "0222.222.222", pub_date: TARGET_DATE,
                         zip_code_id: @anvers.id, probably_new: false, entity_name: "VZW 2", known: true)

      # Enterprise : followed --- Zip Code : followed --- Date : OK
      Publication.create(file_name: "file_3.pdf", cbe_number: "0333.333.333", pub_date: TARGET_DATE,
                         zip_code_id: @leuven.id, probably_new: false, entity_name: "SRL 1", known: true)

      # Enterprise : not followed --- Zip Code : followed --- Date : OK
      Publication.create(file_name: "file_4.pdf", cbe_number: "0444.444.444", pub_date: TARGET_DATE,
                         zip_code_id: @liege.id, probably_new: false, entity_name: "BV 2", known: true)

      # Enterprise : not followed --- Zip Code : followed --- Date : OK
      Publication.create(file_name: "file_4_bis.pdf", cbe_number: "0444.444.444", pub_date: TARGET_DATE,
                         zip_code_id: @liege.id, probably_new: false, entity_name: "BV 2", known: true)

      # Enterprise : not followed --- Zip Code : not followed --- Date : OK
      Publication.create(file_name: "file_5.pdf", cbe_number: "0555.555.555", pub_date: TARGET_DATE,
                         zip_code_id: @namur.id, probably_new: false, entity_name: "Commune 1", known: true)

      # Enterprise : not followed --- Zip Code : not followed --- Date : OK
      Publication.create(file_name: "file_6.pdf", cbe_number: "0666.666.666", pub_date: TARGET_DATE,
                         zip_code_id: @charleroi.id, probably_new: false, entity_name: "Gemeente 2", known: true)

      # Enterprise : followed --- Zip Code : not followed --- Date : NOK
      Publication.create(file_name: "file_7.pdf", cbe_number: "0111.111.111", pub_date: TARGET_DATE - 1,
                         zip_code_id: @brussels.id, probably_new: false, entity_name: "ASBL 1", known: true)

      # Enterprise : not followed --- Zip Code : followed --- Date : NOK
      Publication.create(file_name: "file_8.pdf", cbe_number: "0444.444.444", pub_date: TARGET_DATE - 2,
                         zip_code_id: @liege.id, probably_new: false, entity_name: "BV 2", known: true)

      super
    end
  end

  def test_returns_correct_results_for_user_with_matching_zip_codes_enterprises_and_date
    results_manager = Yocm::ResultsManager.new(@user, TARGET_DATE)

    zip_code_results = results_manager.zip_code_results
    assert zip_code_results.match
    assert_equal 2, zip_code_results.matching.count
    refute_empty zip_code_results.matching.select { _1.code == @leuven.code }
    refute_empty zip_code_results.matching.select { _1.code == @liege.code }
    assert_equal 1, zip_code_results.matching.select { _1.code == @leuven.code }.first.num_matches
    assert_equal 2, zip_code_results.matching.select { _1.code == @liege.code }.first.num_matches

    enterprise_results = results_manager.enterprise_results
    assert enterprise_results.match
    assert_equal 3, enterprise_results.matching.count

    matching_cbe_numbers = enterprise_results.matching.map(&:cbe_number)

    assert_includes matching_cbe_numbers, "0111.111.111"
    assert_includes matching_cbe_numbers, "0222.222.222"
    assert_includes matching_cbe_numbers, "0333.333.333"

    matching_denominations = enterprise_results.matching.map(&:denomination)

    assert_includes matching_denominations, "ASBL 1"
    assert_includes matching_denominations, "VZW 2"
    assert_includes matching_denominations, "SRL 1"
  end
end
