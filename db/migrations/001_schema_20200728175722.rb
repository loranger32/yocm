Sequel.migration do
  change do
    create_table(:addresses) do
      primary_key :id
      column :enterprise_id, "character(12)", null: false
      column :type_of_address, "character(4)", null: false
      column :country_nl, "character varying(100)"
      column :country_fr, "character varying(100)"
      column :zip_code, "character varying(20)"
      column :municipality_fr, "character varying(200)"
      column :municipality_nl, "character varying(200)"
      column :street_nl, "character varying(200)"
      column :street_fr, "character varying(200)"
      column :house_number, "character varying(22)"
      column :box, "character varying(20)"
      column :extra_address_info, "character varying(80)"
      column :date_striking_of, "date"

      index [:enterprise_id]
    end

    create_table(:denominations) do
      primary_key :id
      column :enterprise_id, "character(12)", null: false
      column :language, "character(1)", null: false
      column :type_of_denomination, "character(3)", null: false
      column :description, "character varying(320)", null: false

      index [:enterprise_id]
    end

    create_table(:enterprises) do
      column :id, "character(12)", null: false
      column :juridical_situation, "character(3)", null: false
      column :type_of_enterprise, "character(1)", null: false
      column :juridical_form, "character(3)"
      column :start_date, "date", null: false

      primary_key [:id]
    end

    create_table(:zip_codes) do
      primary_key :id
      column :code, "character(4)", null: false
      column :village, "text"
      column :city, "text", null: false
      column :province, "text"

      index [:city]
      index [:code]
      index [:province]
    end

    create_table(:publications) do
      primary_key :id
      column :file_name, "text", null: false
      column :cbe_number, "character(12)", null: false
      column :pub_date, "date", null: false
      column :complete, "boolean", null: false
      foreign_key :zip_code_id, :zip_codes, key: [:id]

      index [:file_name], name: :publications_file_name_key, unique: true
    end
  end
end
