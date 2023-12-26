Sequel.migration do
  up do
    alter_table(:addresses) do
      drop_constraint :addresses_pkey
      drop_column :id
      rename_column :enterprise_id, :id
      add_primary_key [:id], name: :address_pkey
    end
  end

  down do
    alter_table(:addresses) do
      drop_constraint :address_pkey
      rename_column :id, :enterprise_id
      add_primary_key :id
    end
  end
end
