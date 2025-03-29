class Publication < Sequel::Model
  dataset_module do
    def count_zip_code_errors(publications)
      publications.count { _1.zip_code_id == 1 }
    end

    def count_probably_new(publications)
      publications.count(&:probably_new)
    end

    def from_date(date)
      where(pub_date: date)
    end

    def last_pub_date
      distinct.select_order_map(:pub_date).last
    end

    def count_all_from_date(date)
      from_date(date).count
    end

    def count_complete_from_date(date)
      where(pub_date: date).exclude(zip_code_id: 1).count
    end

    def count_incomplete_from_date(date)
      where(pub_date: date, zip_code_id: 1).count
    end

    def count_zip_errors_from_date(date)
      from_date(date).where(zip_code_id: 1).count
    end

    def count_probably_new_from_date(date)
      where(pub_date: date, probably_new: true).count
    end

    def next_zip_error_publication(pub_date)
      where(pub_date: pub_date, zip_code_id: 1).first
    end

    def pub_dates
      distinct.select_order_map(:pub_date).reverse
    end

    def zip_code_counts_for_date(zip_code_ids, pub_date)
      where(zip_code_id: zip_code_ids, pub_date: pub_date)
        .group_and_count(:zip_code_id)
        .select_hash(:zip_code_id, :count)
        .transform_keys { |id| ZipCode[id] }
    end

    def daily_publications_matching_enterprises_count_for(enterprises_ids, pub_date)
      where(cbe_number: enterprises_ids, pub_date: pub_date).count
    end

    def daily_publications_matching_enterprises_for(enterprises_ids, pub_date)
      where(cbe_number: enterprises_ids, pub_date: pub_date).all
    end

    def daily_publications_matching_zip_codes_count_for(zip_codes_ids, pub_date)
      Publication.where(zip_code_id: zip_codes_ids, pub_date: pub_date).count
    end

    def daily_publications_matching_zip_codes_for(zip_codes_ids, pub_date)
      Publication.where(zip_code_id: zip_codes_ids, pub_date: pub_date).all
    end
  end

  def self.valid_pub_file_name?(file_name)
    file_name.match?(/\A\d{8}.pdf\z/)
  end

  def zip_code
    ZipCode[zip_code_id].code
  end

  def city
    ZipCode[zip_code_id].city_fr.capitalize
  end

  def zip_and_city
    if complete?
      "#{zip_code} #{city}"
    else
      "Unknown zip code"
    end
  end

  def complete?
    zip_code_id != 1
  end

  # May return nil if new entity
  def enterprise
    Enterprise.where(id: cbe_number).first
  end
end
