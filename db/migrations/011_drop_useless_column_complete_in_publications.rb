Sequel.migration do
  up do
    alter_table(:publications) do
      drop_column :complete
    end
  end

  down do
    alter_table(:publications) do
      add_column :complete, "boolean"
    end
  end
end
