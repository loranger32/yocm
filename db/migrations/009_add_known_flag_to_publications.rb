Sequel.migration do
  change do
    alter_table(:publications) do
      add_column :known, TrueClass
    end
  end
end
