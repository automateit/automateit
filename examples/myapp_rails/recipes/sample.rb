# Setup Rails on hosts tagged "rails_servers" or "myapp_servers"
if tagged?("rails_servers | myapp_servers")
  # Install system-level packages, if needed
  if tagged?("ubuntu | debian")
    package_manager.install(%w(build-essential swig ruby1.8-dev libsqlite3-dev pen))
  elsif tagged?("fedoracore | redhat | centos")
    package_manager.install(%w(ruby-devel sqlite-devel pen))
  else
    raise NotImplementedError.new("no packages specified for this platform")
  end

  # Install Ruby gems, if needed
  package_manager.install(%w(rails mongrel mongrel_cluster sqlite3-ruby), :with => :gem)
end

# Install myapp app
if tagged?("myapp_servers")
  # Create a user login, if needed
  account_manager.add_user(lookup("myapp#user"))
  mkdir_p(lookup("myapp#path")) do
    chown(lookup("myapp#user"), nil, ".")

    # Track changes so we know when to restart the Rails server
    restart_needed= false

    # Create Rails application, if needed
    sh("su #{lookup('myapp#user')} -c 'rails --database=sqlite3 .'") unless File.exists?("config/routes.rb")

    # Create mongrel cluster configuration from template string, if needed
    render(
      :string => \
"<%=WARNING_BOILERPLATE%>

cwd: <%=path%>
port: <%=port%>
environment: <%=environment%>
pid_file: <%=path%>/log/mongrel.pid
servers: <%=backends%>",
      :to => "config/mongrel_cluster.yml",
      :locals => {
        :environment => lookup("myapp#environment"),
        :path => lookup("myapp#path"),
        :port => lookup("myapp#port"),
        :backends => lookup("myapp#backends"),
      }
    )

    # Instantiate db, if needed
    sh "su #{lookup('myapp#user')} -c 'rake db:migrate'" if Dir["db/*.sqlite3"].empty?

    # Edit a file to set the application name, if needed
    restart_needed |= edit(
      :file => "public/index.html", :params => {:name => lookup("myapp#name")}
    ) do
      append("<!-- Edited by AutomateIt -->")
      replace("Welcome aboard", "This is "+params[:name])
    end

    # Create service by rendering a template file, if needed
    # FIXME dryrun isn't showing this file being rendered
    restart_needed |= render(
      :file => dist+"/etc/init.d/"+lookup("myapp#name")+".erb",
      :to => "/etc/init.d/"+lookup("myapp#name"),
      :mode => 0555,
      :locals => {
        :name => lookup("myapp#name"),
        :user => lookup("myapp#user"),
        :path => lookup("myapp#path"),
        :bind => lookup("myapp#bind"),
        :port => lookup("myapp#port"),
        :backends => lookup("myapp#backends"),
      }
    )

    # Enable service to run on boot, if needed
    service_manager.enable(lookup("myapp#name"))

    # Start or restart service, if needed
    if service_manager.running?(lookup("myapp#name")) and restart_needed
      # FIXME it's always restarting it even if it's not running
      service_manager.tell(lookup("myapp#name"), "restart")
    else
      service_manager.start(lookup("myapp#name"))
    end
  end
end

