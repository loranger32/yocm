class Enterprise < Sequel::Model
  one_to_many :denominations
  one_to_many :establishments
  many_to_many :juridical_forms
  one_to_one :branch

  def address
    company? ? Address[id] : Address[establishments.first.id]
  end

  def belgian_address
    if foreign_entity?
      if has_establishment?
        Address.where(id: establishments.map(&:id), country_fr: nil).first # Belgian addresses have a null value for the country_fr table
      elsif has_branch?
        Address.where(id: branch.id).first # Only one belgian branch per entity
      else
        address # In the rare case there is no known belgian address, use the foreign one to avoid nil return value
      end
    else
      address
    end
  end

  def belgian_box?
    !belgian_address.box.empty?
  end

  def belgian_box
    belgian_address.box
  end

  def belgian_street_and_number
    "#{belgian_address.street_fr} #{belgian_address.house_number}"
  end

  def belgian_zip_and_city
    "#{belgian_address.zip_code} #{belgian_address.municipality_fr}"
  end

  def belgian_zip_code_id
    ZipCode.where(code: belgian_address.zip_code).first&.id || 1
  end

  def box
    address.box
  end

  def box?
    !address.box.empty?
  end

  def company?
    type_of_enterprise == "2"
  end

  def country_fr
    address.country_fr || "Belgique"
  end

  def country_fr_and_nl
    country_fr + " / " + country_nl
  end

  def country_nl
    address.country_nl || "België"
  end

  def foreign_entity?
    juridical_form_id == "030"
  end

  def has_establishment?
    !establishments.empty?
  end

  def has_branch?
    !branch.nil?
  end

  def juridical_form(language=nil)
    query = DB[:juridical_forms].where(code: juridical_form_id)

    case language
    when "FR" then query.where(language: "FR").first[:name]
    when "NL" then query.where(language: "NL").first[:name]
    when "DE" then query.where(language: "DE").first[:name]
    else
      query.where(language: "FR").first[:name]
    end
  end

  def name
    denominations.first.description
  end

  def publications
    Publication.where(cbe_number: id).all
  end

  def publications_of_the_day(pub_date)
    Publication.where(cbe_number: id, pub_date: pub_date).all
  end

  def street_and_number
    "#{address.street_fr} #{address.house_number}"
  end

  def zip_and_city
    "#{address.zip_code} #{address.municipality_fr}"
  end
end
