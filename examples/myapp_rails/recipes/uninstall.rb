if tagged?("myapp_servers")
  service_manager.stop(lookup("myapp#name"))
  rm("/etc/init.d/"+lookup("myapp#name"))
  account_manager.remove_user(lookup("myapp#user"))
  if tagged?("rheya")
    package_manager.uninstall(%w(mongrel_cluster mongrel daemons fastthread cgi_mutlipart_eof_fix), :with => :gem)
  end
end
