# frozen_string_literal: true

require_relative "test_helpers"
require_relative "../yocm/lib/csv_metadata"
require_relative "../yocm/lib/cbe_data_handler"

class CBEDataHandlerTest < HookedTestClass

  def around
    assert @cbe_tables.all?(&:empty?)
    DB.transaction(rollback: :always, savepoint: true, auto_savepoint: true) do
      super
    end
    assert @cbe_tables.all?(&:empty?)
  end

  def around_all
    @cbe_data_handler = Yocm::CBEDataHandler.new(db: DB)
    @cbe_tables = [DB[:addresses], DB[:branches],DB[:cbe_metadata], DB[:denominations],
      DB[:enterprises], DB[:establishments], DB[:juridical_forms]]

    DB.transaction(:rollback=>:always) do
      super
    end
  end

  def assert_initial_state_after_import
    assert_equal 9, DB[:enterprises].count
    assert_equal 6, DB[:denominations].count
    assert_equal 13, DB[:addresses].count
    assert_equal 9, DB[:establishments].count
    assert_equal 9, DB[:juridical_forms].count
    assert_equal 2, DB[:branches].count
  end

  def test_import_all_cbe_data_when_no_data_present
    assert @cbe_tables.all?(&:empty?)

    capture_io { @cbe_data_handler.import }

    assert_initial_state_after_import
    assert_equal 1, DB[:cbe_metadata].count
    assert_equal 3, DB[:cbe_metadata].first[:extract_number]
  end

  def test_does_not_import_cbe_data_when_branches_data_already_present
    DB[:branches].insert(id: "9.123.456.789", start_date: "01-01-2000", enterprise_id: "0123.456.789")
    assert_equal 1, DB[:branches].count
    assert_raises(Yocm::CBEDataHandler::Error) { @cbe_data_handler.import }
    assert_equal 1, DB[:branches].count
    assert DB[:addresses].empty?
    assert DB[:cbe_metadata].empty?
    assert DB[:denominations].empty?
    assert DB[:enterprises].empty?
    assert DB[:establishments].empty?
    assert DB[:juridical_forms].empty?
  end

  def test_does_not_import_cbe_data_when_enterprise_data_already_present
    DB[:enterprises].insert(id: "0123.456.789", juridical_situation: "002", type_of_enterprise: "1", start_date: "01-01-2022")
    assert DB[:enterprises].count == 1
    assert_raises(Yocm::CBEDataHandler::Error) { @cbe_data_handler.import }
    assert DB[:addresses].empty?
    assert DB[:branches].empty?
    assert DB[:cbe_metadata].empty?
    assert DB[:denominations].empty?
    assert_equal 1, DB[:enterprises].count
    assert DB[:establishments].empty?
    assert DB[:juridical_forms].empty?
  end

  def test_does_not_import_cbe_data_when_addresses_data_already_present
    DB[:addresses].insert(id: "0123.456.789", type_of_address: "REGO")
    assert_equal 1, DB[:addresses].count
    assert_raises(Yocm::CBEDataHandler::Error) { @cbe_data_handler.import }
    assert_equal 1, DB[:addresses].count
    assert DB[:branches].empty?
    assert DB[:cbe_metadata].empty?
    assert DB[:denominations].empty?
    assert DB[:enterprises].empty?
    assert DB[:establishments].empty?
    assert DB[:juridical_forms].empty?
  end

  def test_does_not_import_cbe_data_when_denominations_data_already_present
    DB[:denominations].insert(enterprise_id: "0123.456.789", language: "1",
      type_of_denomination: "001", denomination: "Fake Denomination")
    assert_equal 1, DB[:denominations].count
    assert_raises(Yocm::CBEDataHandler::Error) { @cbe_data_handler.import }
    assert DB[:addresses].empty?
    assert DB[:branches].empty?
    assert DB[:cbe_metadata].empty?
    assert_equal 1, DB[:denominations].count
    assert DB[:enterprises].empty?
    assert DB[:establishments].empty?
    assert DB[:juridical_forms].empty?
  end

  def test_does_not_import_cbe_data_when_juridical_form_data_already_present
    DB[:juridical_forms].insert(code: "001", language: "FR", name: "Test Form")
    assert_equal 1, DB[:juridical_forms].count
    assert_raises(Yocm::CBEDataHandler::Error) { @cbe_data_handler.import }
    assert DB[:addresses].empty?
    assert DB[:branches].empty?
    assert DB[:cbe_metadata].empty?
    assert DB[:denominations].empty?
    assert DB[:enterprises].empty?
    assert DB[:establishments].empty?
    assert_equal 1, DB[:juridical_forms].count
  end

  def test_does_not_import_cbe_data_when_establishments_data_already_present
    DB[:establishments].insert(id: "2.000.000.001", start_date: "01-01-2001", enterprise_id: "111.111.111")
    assert_equal 1, DB[:establishments].count
    assert_raises(Yocm::CBEDataHandler::Error) { @cbe_data_handler.import }
    assert DB[:addresses].empty?
    assert DB[:branches].empty?
    assert DB[:cbe_metadata].empty?
    assert DB[:denominations].empty?
    assert DB[:enterprises].empty?
    assert_equal 1, DB[:establishments].count
    assert DB[:juridical_forms].empty?
  end

  def test_rollback_all_transactions_when_error_while_importing
    assert @cbe_tables.all?(&:empty?)

    # Simulate a NameError by undefining the last import method
    Yocm::CBEDataHandler.class_eval do
      alias_method :real_import_address_method, :import_addresses
      remove_method :import_addresses
    end

    assert_raises(NameError) { @cbe_data_handler.import }
    assert @cbe_tables.all?(&:empty?)

    # Back to normal
  ensure
    Yocm::CBEDataHandler.class_eval do
      alias_method :import_addresses, :real_import_address_method
      remove_method :real_import_address_method
    end
  end

  def test_updates_when_everything_ok
    capture_io { @cbe_data_handler.import }

    # Simulates the actual dataset is older than the one in the test file
    DB[:cbe_metadata].update(extract_number: 2)

    capture_io { @cbe_data_handler.update }

    # Assert presence of updated record and refute presence of to delete record
    assert_equal 1, DB[:enterprises].where(id: "0777.777.777").count
    assert_equal 1, DB[:denominations].where(enterprise_id: "0777.777.777").count
    assert_equal 1, DB[:addresses].where(id: "0777.777.777").count
    assert_equal 1, DB[:establishments].where(enterprise_id: "0777.777.777").count
    assert_equal 1, DB[:branches].where(id: "9.111.555.555").count

    assert DB[:enterprises].where(id: "0111.111.111").empty?
    assert DB[:denominations].where(enterprise_id: "0111.111.111").empty?
    assert DB[:addresses].where(id: "0111.111.111").empty?
    assert DB[:establishments].where(enterprise_id: "0111.111.111").empty?
    assert DB[:branches].where(id: "9.111.444.444").empty?
  end

  def test_does_not_update_when_no_data_to_update
    assert @cbe_tables.all?(&:empty?)
    assert_raises(Yocm::CBEDataHandler::Error) do
      @cbe_data_handler.update
    end
    assert @cbe_tables.all?(&:empty?)
  end

  def test_does_not_update_when_no_extract_number_found
    assert @cbe_tables.all?(&:empty?)
    capture_io { @cbe_data_handler.import }
    DB[:cbe_metadata].delete

    assert_raises(Yocm::CBEDataHandler::Error) { @cbe_data_handler.update }

    # Assert the original data set is unchanged (except for cbe_metadata - trick for the test to work)
    assert_initial_state_after_import
    assert DB[:cbe_metadata].empty? # CBE number has been deleted

    assert DB[:enterprises].where(id: "0777.777.777").empty?
    assert DB[:denominations].where(enterprise_id: "0777.777.777").empty?
    assert DB[:addresses].where(id: "0777.777.777").empty?
    assert DB[:establishments].where(enterprise_id: "0777.777.777").empty?
    assert DB[:branches].where(id: "9.111.555.555").empty?
  end

  def test_does_not_update_when_extract_number_does_not_match
    assert @cbe_tables.all?(&:empty?)
    capture_io { @cbe_data_handler.import }

    # Simulates a new dataset
    DB[:cbe_metadata].insert(snapshot_date: "01-04-2022",
      extract_time_stamp: "03-04-2022 17:14:10",
      extract_type: "update",
      extract_number: 5, # Input param from csv is 3, should be 4 to update
      version: "1.0.0")
    assert_raises(Yocm::CBEDataHandler::Error) { @cbe_data_handler.update }

    # Assert the original data set is unchanged
    assert_initial_state_after_import
    assert_equal 2, DB[:cbe_metadata].count # New metadata have been inserted
    assert_equal 3, DB[:cbe_metadata].first[:extract_number]
 
    assert DB[:enterprises].where(id: "0777.777.777").empty?
    assert DB[:denominations].where(enterprise_id: "0777.777.777").empty?
    assert DB[:addresses].where(id: "0777.777.777").empty?
    assert DB[:establishments].where(enterprise_id: "0777.777.777").empty?
    assert DB[:branches].where(id: "9.111.555.555").empty?
  end

  def test_does_not_update_when_data_already_up_to_date
    assert @cbe_tables.all?(&:empty?)
    capture_io { @cbe_data_handler.import }

    assert_raises(Yocm::CBEDataHandler::Error) { @cbe_data_handler.update }

    assert_initial_state_after_import

    assert DB[:enterprises].where(id: "0777.777.777").empty?
    assert DB[:denominations].where(enterprise_id: "0777.777.777").empty?
    assert DB[:addresses].where(id: "0777.777.777").empty?
    assert DB[:establishments].where(enterprise_id: "0777.777.777").empty?
    assert DB[:branches].where(id: "9.111.555.555").empty?
  end

  def test_rollback_all_transactions_when_error_while_updating
    assert @cbe_tables.all?(&:empty?)
    capture_io { @cbe_data_handler.import }

    # Simulates the actual dataset is older than the one in the test file
    DB[:cbe_metadata].update(extract_number: 2)

    # Simulate a NameError by undefining one of the last update method
    Yocm::CBEDataHandler.class_eval do
      alias_method :real_update_juridical_forms_method, :update_juridical_forms
      remove_method :update_juridical_forms
    end

    assert_raises(NameError) { @cbe_data_handler.update }

    assert_initial_state_after_import
    assert_equal 2, DB[:cbe_metadata].first[:extract_number]
    assert DB[:enterprises].where(id: "0777.777.777").empty?
    assert DB[:denominations].where(enterprise_id: "0777.777.777").empty?
    assert DB[:addresses].where(id: "0777.777.777").empty?
    assert DB[:establishments].where(enterprise_id: "0777.777.777").empty?
    assert DB[:branches].where(id: "9.111.555.555").empty?

    # Back to normal
  ensure
    Yocm::CBEDataHandler.class_eval do
      alias_method :update_juridical_forms, :real_update_juridical_forms_method
      remove_method :real_update_juridical_forms_method
    end
  end

  def test_clean_cbe_data
    capture_io { @cbe_data_handler.import }
    refute @cbe_tables.any?(&:empty?)
    capture_io { @cbe_data_handler.delete_cbe_data }
    assert @cbe_tables.all?(&:empty?)
  end
end
