Sequel.migration do
  change do
    create_table(:establishments) do
      String :id, fixed: true, size: 13, null: false, primary_key: true
      Date :start_date, null: false
      String :enterprise_id, fixed: true, size: 12, null: false

      index :enterprise_id
    end
  end
end
