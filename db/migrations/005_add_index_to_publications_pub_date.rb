Sequel.migration do
  change do
    alter_table(:publications) do
      add_index :pub_date
    end
  end
end 