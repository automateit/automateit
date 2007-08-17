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
