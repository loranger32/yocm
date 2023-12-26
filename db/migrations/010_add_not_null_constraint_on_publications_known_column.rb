Sequel.migration do
  up do
    alter_table(:publications) do
      set_column_not_null :known
    end
  end

  down do
    alter_table(:publications) do
      set_column_allow_null :known
    end
  end
end
