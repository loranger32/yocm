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

  def has_enterprise_to_manage?
    can_merge_cbe_numbers? || has_orphaned_publications?
  end

  def has_orphaned_publications?
    !orphaned_publications.empty?
  end

  # New publications that are not yet in the local DB have their cbe number that starts with 1.
  def orphaned_publications
    publications.select do |publication|
      Enterprise[publication.cbe_number].nil? && publication.cbe_number.start_with?("0")
    end
  end

  def drop_orphaned_publications!
    return false unless has_orphaned_publications?

    num_to_drop = orphaned_publications.size
    orphaned_publications.each { remove_publication(_1) }

    num_to_drop
  end

  def merge_cbe_numbers_from_publications!
    return false unless can_merge_cbe_numbers?

    pubs_to_delete = Publication.where(cbe_number: overlapping_enterprise_records.map(&:id)).all
    enterprises_to_add = (overlapping_enterprise_records - enterprises).count

    report = {}
    report[:enterprises_added] = enterprises_to_add.count
    report[:publications_dropped] = pubs_to_delete.count

    DB.transaction do
      enterprises_to_add.each { add_enterprise(_1) }
      pubs_to_delete.each { remove_publication(_1) }
    end

    report
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
