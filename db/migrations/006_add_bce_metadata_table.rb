Sequel.migration do
 change do
  create_table(:cbe_metadata) do
    Date :snapshot_date, null: false
    DateTime :extract_time_stamp, null: false
    String :extract_type, null: false
    Integer :extract_number, null: false, unique: true, primary_key: true
    String :version, null: false, size: 8
  end
 end
end
