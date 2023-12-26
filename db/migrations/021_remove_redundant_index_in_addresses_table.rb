Sequel.migration do
  up do
    alter_table(:addresses) do
      drop_index :id, name: :addresses_enterprise_id_index
    end
  end

  down do
    alter_table(:addresses) do
      add_index :id, name: :addresses_enterprise_id_index
    end
  end
end