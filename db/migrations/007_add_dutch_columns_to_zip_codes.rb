Sequel.migration do
  up do
    alter_table(:zip_codes) do
      drop_index :city
      drop_index :province
      rename_column :village, :village_fr
      rename_column :city, :city_fr
      rename_column :province, :province_fr
      add_column :village_nl, String
      add_column :city_nl, String, null: false
      add_column :province_nl, String
    end
  end

  down do
    alter_table(:zip_codes) do
      drop_column :village_nl
      drop_column :city_nl
      drop_column :province_nl
      rename_column :village_fr, :village
      rename_column :city_fr, :city
      rename_column :province_fr, :province
      add_index [:city]
      add_index [:province]
    end
  end
end