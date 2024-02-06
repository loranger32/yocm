class ZipCode < Sequel::Model

  plugin :static_cache unless ENV["RUN_ENV"] == "test"

  many_to_many :users

  def self.loaded?
    zip_code_count_ok? && first_zip_code_is_unknown? && last_zip_code_is_middelburg?
  end

  def self.zip_code_count_ok?
    count == 2765
  end

  def self.first_zip_code_is_unknown?
    self[1].code == "0000"
  end

  def self.last_zip_code_is_middelburg?
    self[2765].code == "9992"
  end
end
