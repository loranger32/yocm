require_relative "test_helpers"
require_relative "../yocm/lib/user_manager_class"

class UserManagerInitializeTest < Minitest::Test
  def test_initialize_validates_valid_args
    [nil, false, 1].each do |arg|
      assert_silent { Yocm::UserManager.new(arg) }
    end
  end

  def test_initialize_raises_with_invalid_args
    ["1", "a long invalid string", :invalid].each do |arg|
      assert_raises(::Yocm::UserManager::Error) { Yocm::UserManager.new(arg) }
    end
  end
end

class UserManagerUserInfoTest < HookedTestClass
  def around_all
    DB.transaction(rollback: :always) do
      User.create(email: "test_inactive@example.com", active: false)
      User.create(email: "test_active@example.com", active: true)
      super
    end
  end

  def test_user_info_return_correct_user_info_with_option_no_user_passed
    info = Yocm::UserManager.new(false).user_info!
    assert_nil info.user
    assert_equal true, info.no_user_option
  end

  def test_user_info_return_correct_user_info_with_existing_user_required
    user = User[1]
    info = Yocm::UserManager.new(1).user_info!

    assert_equal user, info.user
    refute info.no_user_option
  end

  def test_user_info_return_correct_user_info_with_default_setting_and_active_user_present
    active_user = User.where(active: true).first
    info = Yocm::UserManager.new(nil).user_info!

    assert_equal active_user, info.user
    refute info.no_user_option
  end

  def test_user_info_return_correct_info_with_default_setting_and_no_active_user
    DB.transaction(rollback: :always) do
      DB[:users].delete
        info = Yocm::UserManager.new(nil).user_info!

        assert_nil info.user
        refute info.no_user_option
    end

    DB.transaction(rollback: :always) do
      User.active.update(active: false)
      info = Yocm::UserManager.new(nil).user_info!

      assert_nil info.user
      assert_equal false, info.no_user_option
    end
  end

  def test_user_manager_predicate_user_selected_class_method
    user = User[1]
    user_info = Yocm::UserManager.new(1).user_info!

    assert Yocm::UserManager.user_selected?(user_info)
  end
end
