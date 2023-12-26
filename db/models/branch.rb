class Branch < Sequel::Model
  many_to_one :enterprise # This is one to one relationship, but needed for Sequel

  def address
    Address[id]
  end
end