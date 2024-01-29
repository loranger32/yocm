Sequel.migration do
  change do
    alter_table(:publications) do
      add_index :cbe_number, name: "publications_cbe_number_index"
    end
  end
end
