# Install packages on machines tagged 'rails_servers' or 'myapp_servers'
if tagged?("rails_servers | myapp_servers")
  # Install platform-specific packages, queries system-provided tags
  if tagged?("ubuntu | debian")
    package_manager.install(%w(ruby1.8-dev libsqlite3-dev))
  elsif tagged?("fedoracore")
    package_manager.install(%w(ruby-devel sqlite-devel))
  else
    raise NotImplementedError.new("no packages specified for this platform")
  end

  # Install Gems
  package_manager.install(%w(rails sqlite3-ruby mongrel),
    :with => :gem, :docs => false)
end

# Setup the myapp server
if tagged?(:myapp_servers)
  # Create a directory for the application
  mkdir_p(lookup(:path)) do
    # Run shell commands to create the app and database
    sh("rails --database=sqlite3 . > /dev/null") \
      unless File.exists?("config/routes.rb")

    sh("rake db:migrate") if Dir["db/*.sqlite3"].empty?

    # Edit the homepage
    edit(:file => "public/index.html") do
      append("<!-- Edited by AutomateIt -->")
      replace("Welcome aboard", "This is MyAppServer")
    end

    # Change the ownership for the files
    chown_R(lookup(:user), nil, ".")

    # Generate a service startup file from a template
    render(:file => dist+"myapp_server.erb",
           :to => "/etc/init.d/myapp_server",
           :mode => 0555,
           :locals => {
              :path => lookup(:path),
              :user => lookup(:user),
              :port => lookup(:port),
           }
    )

    # Start the service
    service_manager.start("myapp_server")
  end
end
