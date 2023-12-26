Sequel.migration do
  change do
    alter_table(:enterprises) do
      add_column :juridical_form_cac, String, fixed: true, size: 3
    end
  end
end