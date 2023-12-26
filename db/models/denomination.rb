class Denomination < Sequel::Model
  many_to_one :enterprise

  # Nicer to call denomination.description than denomination.denomination
  alias_method :description, :denomination
end
