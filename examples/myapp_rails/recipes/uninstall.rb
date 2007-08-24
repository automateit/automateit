if tagged?("myapp_servers")
  service_manager.stop(lookup("myapp#name"))
  rm("/etc/init.d/"+lookup("myapp#name"))
  account_manager.remove_user(lookup("myapp#user"))
end
