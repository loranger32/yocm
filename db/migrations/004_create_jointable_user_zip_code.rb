Sequel.migration do
  change do
    create_join_table(user_id: :users, zip_code_id: :zip_codes)
  end
end
