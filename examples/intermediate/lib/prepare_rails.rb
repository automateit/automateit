def prepare_rails()
  # Install system-level packages, if needed
  if tagged?("ubuntu | debian")
    package_manager.install(
      %w(ruby1.8-dev libsqlite3-dev pen))
  elsif tagged?("fedoracore | redhat | centos")
    package_manager.install(%w(ruby-devel sqlite-devel pen))
  else
    raise NotImplementedError.new("no packages specified for this platform")
  end

  # Install Ruby gems, if needed
  package_manager.install(%w(rails mongrel mongrel_cluster sqlite3-ruby),
    :with => :gem, :docs => false)
end
