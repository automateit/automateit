# Install dependencies on hosts with 'rails_servers' or 'myapp_servers' roles
if tagged?("rails_servers | myapp_servers")
  # Install platform-specific packages
  if tagged?("ubuntu | debian")
    # Install the 'build-essential' package and others on Ubuntu or Debian
    package_manager.install("build-essential", "ruby1.8-dev", "libsqlite3-dev")
  elsif tagged?("fedoracore | fedora | centos")
    # Install equivalent packages on Fedora and similar OSes
    package_manager.install("gcc", "'ruby-devel", "sqlite-devel")
  else
    # Fail if running on another platform
    raise NotImplementedError.new("no packages specified for this platform")
  end

  # Install Rails and supporting libraries with RubyGems
  package_manager.install("rails", "sqlite3-ruby", "mongrel",
    :with => :gem, :docs => false)
end # ENDS: if tagged?("rails_servers | myapp_servers")

# Setup the myapp server, a simple Rails server instance
if tagged?(:myapp_servers)
  # Create user for the application
  account_manager.add_user(lookup(:user))

  # Create a directory for the application and 'cd' into it
  mkdir_p(lookup(:path)) do
    # Run shell commands to create the app and database
    unless File.exists?("config/routes.rb")
      sh("rails --database=sqlite3 . > /dev/null")
    end

    # Create the database if it doesn't exist.
    if Dir["db/*.sqlite3"].empty?
      sh("rake db:migrate")
    end

    # Edit the homepage
    edit(:file => "public/index.html") do
      append("<!-- Edited by AutomateIt -->")
      replace("Welcome aboard", "This is MyAppServer")
    end

    # Set the ownership of the created files
    chperm(".", :user => lookup(:user), :recurse => true)

    # Generate a service startup file using a template
    render(
      :file => dist+"myapp_server.erb",
      :to => "/etc/init.d/myapp_server",
      :mode => 0555,
      :locals => {
        :path => lookup(:path),
        :user => lookup(:user),
        :port => lookup(:port),
      }
    )

    # Start the server
    service_manager.start("myapp_server")
  end # ENDS: mkdir_p(lookup(:path)) do
end # ENDS: if tagged?(:myapp_servers)
