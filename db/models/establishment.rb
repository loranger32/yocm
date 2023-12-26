class Establishment < Sequel::Model
  many_to_one :enterprise

  def address
    Address[id]
  end
end
