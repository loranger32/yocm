Sequel.migration do
  change do
    create_table(:publications_users, without_rowid: true) do
      foreign_key :publication_id, :publications, null: false, key: :id, on_delete: :cascade
      foreign_key :user_id, :users, null: false, key: :id, on_delete: :cascade

      primary_key [:publication_id, :user_id]
    end
  end
end
