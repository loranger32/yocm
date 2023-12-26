Sequel.migration do
  change do
    create_table(:branches) do
      String :id, size: 13, null: false, primary_key: true
      Date :start_date, null: false
      String :enterprise_id, size: 13, null: false
    end
  end
end