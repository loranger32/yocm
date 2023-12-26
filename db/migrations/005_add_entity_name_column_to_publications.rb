Sequel.migration do
  change do
    alter_table(:publications) do
      add_column :entity_name, String, size: 250, null: false, default: "Unknown name"
    end
  end
end
