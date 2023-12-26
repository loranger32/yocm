Sequel.migration do
  change do
    alter_table(:publications) do
      add_column :probably_new, TrueClass, null: false, default: false
    end
  end
end
