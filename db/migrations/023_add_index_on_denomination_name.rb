Sequel.migration do
  change do
    alter_table(:denominations) { add_index :denomination }
  end
end
