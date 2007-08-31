if tagged? :myapp_servers
  service_manager.stop "myapp_server"
  rm "/etc/init.d/myapp_server"
  rm_rf lookup(:path)
end
