Sequel.migration do
  change do
    create_table(:addresses) do
      column :id, "character varying(13)", :null=>false
      column :type_of_address, "character(4)", :null=>false
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
      
      primary_key [:id]
    end
    
    create_table(:branches) do
      column :id, "character varying(13)", :null=>false
      column :start_date, "date", :null=>false
      column :enterprise_id, "character varying(13)", :null=>false
      
      primary_key [:id]
    end
    
    create_table(:cbe_metadata) do
      column :snapshot_date, "date", :null=>false
      column :extract_time_stamp, "timestamp without time zone", :null=>false
      column :extract_type, "TEXT", :null=>false
      primary_key :extract_number, :keep_order=>true
      column :version, "character varying(8)", :null=>false
    end
    
    create_table(:denominations) do
      primary_key :id
      column :enterprise_id, "character varying(13)", :null=>false
      column :language, "character(1)", :null=>false
      column :type_of_denomination, "character(3)", :null=>false
      column :denomination, "character varying(320)", :null=>false
      
      index [:denomination]
      index [:enterprise_id]
    end
    
    create_table(:enterprises) do
      column :id, "character(12)", :null=>false
      column :juridical_situation, "character(3)", :null=>false
      column :type_of_enterprise, "character(1)", :null=>false
      column :juridical_form_id, "character(3)"
      column :start_date, "date", :null=>false
      column :juridical_form_cac_id, "character(3)"
      
      primary_key [:id]
    end
    
    create_table(:establishments) do
      column :id, "character(13)", :null=>false
      column :start_date, "date", :null=>false
      column :enterprise_id, "character(12)"
      
      primary_key [:id]
      
      index [:enterprise_id]
    end
    
    create_table(:juridical_forms) do
      column :code, "character(3)", :null=>false
      column :language, "character(2)", :null=>false
      column :name, "TEXT", :null=>false
      
      primary_key [:code, :language]
    end
    
    create_table(:schema_info) do
      column :version, "INTEGER", :default=>0, :null=>false
    end
    
    create_table(:users) do
      primary_key :id
      column :email, "character varying(50)", :null=>false
      
      index [:email], :name=>:users_email_key, :unique=>true
    end
    
    create_table(:zip_codes) do
      primary_key :id
      column :code, "character(4)", :null=>false
      column :village_fr, "TEXT"
      column :city_fr, "TEXT", :null=>false
      column :province_fr, "TEXT"
      column :village_nl, "TEXT"
      column :city_nl, "TEXT", :null=>false
      column :province_nl, "TEXT"
      
      index [:code]
    end
    
    create_table(:enterprises_users) do
      column :enterprise_id, "character(12)", :null=>false
      foreign_key :user_id, :users, :null=>false, :key=>[:id], :on_delete=>:cascade
      
      primary_key [:enterprise_id, :user_id]
      
      index [:enterprise_id, :user_id]
    end
    
    create_table(:publications) do
      primary_key :id
      column :file_name, "TEXT", :null=>false
      column :cbe_number, "character(12)", :null=>false
      column :pub_date, "date", :null=>false
      foreign_key :zip_code_id, :zip_codes, :key=>[:id]
      column :probably_new, "boolean", :default=>false, :null=>false
      column :entity_name, "character varying(250)", :default=>"Unknown name", :null=>false
      column :known, "boolean", :null=>false
      
      index [:cbe_number]
      index [:file_name], :name=>:publications_file_name_key, :unique=>true
    end
    
    create_table(:users_zip_codes) do
      foreign_key :user_id, :users, :null=>false, :key=>[:id]
      foreign_key :zip_code_id, :zip_codes, :null=>false, :key=>[:id]
      
      primary_key [:user_id, :zip_code_id]
      
      index [:zip_code_id, :user_id]
    end
    
    create_table(:publications_users) do
      foreign_key :publication_id, :publications, :null=>false, :key=>[:id], :on_delete=>:cascade
      foreign_key :user_id, :users, :null=>false, :key=>[:id], :on_delete=>:cascade
      
      primary_key [:publication_id, :user_id]
    end
  end
end
