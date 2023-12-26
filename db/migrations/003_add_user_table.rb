Sequel.migration do
  change do
    create_table :users do
      primary_key :id
      String :email, size: 50, null: false, unique: true
    end
  end
end
