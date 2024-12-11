module Yocm
  class UserManager
    class Error < StandardError; end

    UserInfo = Data.define(:user, :no_user_option)

    def initialize(user_id)
      validate_arg(user_id)
      @user_id = user_id
    end

    def user_info!
      # option --no-user has been passed
      if @user_id == false
        $log.success("No User mode selected - no user report will be generated")
        return UserInfo.new(user: nil, no_user_option: true)

      # no option provided : default to active user and if none active, no user
      elsif @user_id.nil?
        active_user = User.active
        if active_user
          $log.success("No specific user selected, reports will be generated for the active user: #{active_user.email} (id: #{active_user.id})")
          return UserInfo.new(user: active_user, no_user_option: false)
        else
          $log.warn("No specific user selected, and no active user in DB. No user report will be generated")
          return UserInfo.new(user: nil, no_user_option: false)
        end
      # option --user has been provided
      else
        user = find_user_or_raise!
        $log.success("Specific user required - report will be generated for #{user.email} (id: #{user.id})")
        return UserInfo.new(user: user, no_user_option: false)
      end
    end

    private

    # if user_id refers to a non existing user,the user of the program
    # should be notified as soon as possible and the script should not run.
    def find_user_or_raise!
      user = User[@user_id]
      raise Error, "No user found with id: #{@user_id}" if user.nil?
      user
    end

    def validate_arg(user_id)
      unless user_id.nil? || user_id == false || user_id.is_a?(Integer)
        raise Error, "UserManager - invalid user option provided : #{@user_id}"
      end
    end
  end
end
