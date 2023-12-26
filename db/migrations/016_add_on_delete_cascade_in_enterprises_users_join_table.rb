Sequel.migration do
  up do
    alter_table(:enterprises_users) do
      drop_foreign_key [:enterprise_id]
      drop_foreign_key [:user_id]

      add_foreign_key [:enterprise_id], :enterprises, on_delete: :cascade
      add_foreign_key [:user_id], :users, on_delete: :cascade
    end
  end

  down do
    alter_table(:enterprises_users) do
      drop_foreign_key [:enterprise_id]
      drop_foreign_key [:user_id]

      add_foreign_key [:enterprise_id], :enterprises
      add_foreign_key [:user_id], :users
    end
  end
end
