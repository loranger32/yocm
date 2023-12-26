Sequel.migration do
  change do
    create_table(:enterprises_users) do
      foreign_key :enterprise_id, :enterprises, type: "character(12)"
      foreign_key :user_id, :users
      primary_key [:enterprise_id, :user_id]
      index [:enterprise_id, :user_id]
    end
  end
end
