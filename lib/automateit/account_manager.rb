=begin
OPTIONS: :name, :passwd, :uid, :gid, :home, :gcos, :fullname, :groups [names or ids], :create_home => true, :shell
add_user(options)
remove_user(options)
edit_user(options)
users[id or name] returns same fields as OPTIONS
add_groups_to_user(user id or name, [names or ids of users]) [or with def order]
add_groups_to_user([names or ids of users], user id or name)


OPTIONS: :name, gid, :users => [names or ids]
add_group(options)
remove_group(options)
edit_group(options)
groups[id or name] returns same fields as OPTIONS
add_users_to_group(group id or name, [names or ids of users]) [or with def order]
add_users_to_group([names or ids of users], group id or name)
=end

module AutomateIt
  class AccountManager < Plugin::Manager

    # TODO implement remaining methods

    def add_user(username, opts={}) dispatch(username, opts) end

    #-----------------------------------------------------------------------

    class Basic < Plugin::Driver
      depends_on :nothing

      def suitability(method, *args)
        return 1
      end
    end # class Basic

    #-----------------------------------------------------------------------

    class POSIX < Basic
      depends_on :programs => %w(useradd usermod userdel groupadd groupmod groupdel)

      def suitability(method, *args)
        return available? ? 2 : 0
      end

      def add_user(username, opts={})
        begin
          Etc.getpwnam(username)
          return true
        rescue ArgumentError
          # TODO pass more arguments
          interpreter.sh("useradd --create-home #{username}")
        end
      end
    end # class POSIX
  end # class AccountManager
end # module AutomateIt
