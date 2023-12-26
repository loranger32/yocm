Sequel.migration do
  change do
    create_table(:juridical_forms) do
      String :code, fixed: true, size: 3, null: false
      String :language, fixed: true, size: 2, null: false
      String :name, null: false
      
      primary_key [:code, :language], name: :juridical_forms_pk
    end
  end
end