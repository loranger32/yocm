class User < Sequel::Model
  plugin :validation_helpers

  many_to_many :zip_codes
  many_to_many :enterprises

  def validate
    super
    validates_presence [:email]
    validates_unique :email
    # regexp found on email regex.com
    validates_format /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i, :email, message: "is not a valid email"
  end

  def before_destroy
    remove_all_zip_codes
    remove_all_enterprises
  end

  def follow_cbe_number?(cbe)
    enterprises.map(&:id).include?(cbe)
  end
end
