class Address < Sequel::Model
  def enterprise
    return Enterprise[id] if Enterprise[id]

    Enterprise[establishment.enterprise_id]
  end

  def establishment
    Establishment[id]
  end
end
