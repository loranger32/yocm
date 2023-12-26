Sequel.migration do
  change do
    alter_table(:denominations) { rename_column :description, :denomination }
  end
end