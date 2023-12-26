Sequel.migration do
  up do
    alter_table(:establishments) { set_column_allow_null :enterprise_id }
  end

  down do
    alter_table(:establishments) { set_column_not_null :enterprise_id }
  end
end
