Sequel.migration do
  change do
    alter_table(:enterprises) do
      rename_column(:juridical_form, :juridical_form_id)
      rename_column(:juridical_form_cac, :juridical_form_cac_id)
    end
  end
end
