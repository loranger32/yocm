class User < Sequel::Model
  plugin :validation_helpers

  many_to_many :zip_codes
  many_to_many :enterprises
  many_to_many :publications

  def validate
    super
    validates_presence [:email]
    validates_unique :email
    # regexp found on email regex.com
    validates_format /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i, :email, message: "is not a valid email"
  end

  def can_merge_cbe_numbers?
    !overlapping_enterprise_records.empty?
  end

  def merge_cbe_numbers_from_publications!
    return false unless can_merge_cbe_numbers?

    ets_to_add_count = overlapping_enterprise_records.count
    pubs_to_delete = Publication.where(cbe_number: overlapping_enterprise_records.map(&:id)).all

    DB.transaction do
      (overlapping_enterprise_records - enterprises).each { add_enterprise(_1) }
      pubs_to_delete.each { remove_publication(_1) }
    end

    "#{pubs_to_delete.count} publications merged into #{ets_to_add_count} enterprises"
  end

  def overlapping_enterprise_records
    Enterprise.where(id: publications.map(&:cbe_number)).all
  end

  def before_destroy
    remove_all_zip_codes
    remove_all_enterprises
  end

  def follow_cbe_number?(cbe)
    enterprises.map(&:id).include?(cbe) ||
      publications.map(&:cbe_number).include?(cbe)
  end

  def follow_no_cbe_number?
    enterprises.empty? && publications.empty?
  end

  def follow_no_zips?
    zip_codes.empty?
  end
end
