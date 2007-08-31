if tagged? "rails_servers | myapp_servers"
  if tagged? "ubuntu | debian"
    package_manager.install %w(ruby1.8-dev libsqlite3-dev)
  elsif tagged? "fedoracore | redhat | centos"
    package_manager.install %w(ruby-devel sqlite-devel)
  else
    raise NotImplementedError.new("no packages specified for this platform")
  end

  package_manager.install %w(rails sqlite3-ruby mongrel),
                          :with => :gem, :docs => false
end

if tagged? :myapp_servers
  mkdir_p lookup(:path) do
    sh "rails --database=sqlite3 . > /dev/null" \
      unless File.exists?("config/routes.rb")

    sh "rake db:migrate" if Dir["db/*.sqlite3"].empty?

    edit :file => "public/index.html" do
      append "<!-- Edited by AutomateIt -->"
      replace "Welcome aboard", "This is MyAppServer"
    end

    chown_R lookup(:user), nil, "."

    render :file => dist+"myapp_server.erb",
           :to => "/etc/init.d/myapp_server",
           :mode => 0555,
           :locals => {
              :path => lookup(:path),
              :user => lookup(:user),
              :port => lookup(:port),
           }

    service_manager.start "myapp_server"
  end
end
