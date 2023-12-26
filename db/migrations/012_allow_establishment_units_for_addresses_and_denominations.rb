Sequel.migration do
  up do
    alter_table(:denominations) do
      set_column_type :enterprise_id, "character varying(13)"
      add_constraint(:enterprise_id_min_length){char_length(enterprise_id) > 11}
    end

    alter_table(:addresses) do
      set_column_type :enterprise_id, "character varying(13)"
      add_constraint(:enterprise_id_min_length){char_length(enterprise_id) > 11}
    end
  end

  down do
    alter_table(:denominations) do
      drop_constraint(:enterprise_id_min_length)
      set_column_type :enterprise_id, "character(12)"
    end

    alter_table(:addresses) do
      drop_constraint(:enterprise_id_min_length)
      set_column_type :enterprise_id, "character(12)"
    end
  end
end
