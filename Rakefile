require 'spec/rake/spectask'

# TODO reoganize this messy Rakefile

task :default => :spec

def load_automateit
  $LOAD_PATH.unshift('lib')
  require 'automateit'
end

#---[ run specs ]-------------------------------------------------------

def specify(*files)
  Spec::Rake::SpecTask.new(:spec_internal) do |t|
    t.rcov = @rcov
    t.rcov_opts = ['--exclude', 'spec']
    #t.rcov_opts = ['--exclude', 'spec', '--aggregate', 'aggregate.rcov']
    t.spec_files = FileList[*files]
  end
  Rake::Task[:spec_internal].invoke
end

desc "Run the unit test suite"
task "spec" do
  target = ENV['F'] || ENV['FILE'] || 'spec/unit/**/*_spec.rb'
  specify(target)
end

desc "Generate a code coverage report for the unit tests in the 'coverage' directory"
task "rcov" do
  @rcov = true
  Rake::Task["spec"].invoke
end

desc "Run all the test suites, including unit and integration"
task "spec:all" do
  specify('spec/unit/**/*_spec.rb', 'spec/functional/**/*_spec.rb', 'spec/integration/**/*_spec.rb')
end

desc "Generate a code coverage report for the unit and integration tests"
task "rcov:all" do
  @rcov = true
  Rake::Task["spec:all"].invoke
end

desc "Print verbose descriptions while running specs"
task "verbose" do
  ENV["SPEC_OPTS"] = "-fs"
end

#---[ calculate LOC ]---------------------------------------------------

class Numeric
  def commify() (s=self.to_s;x=s.length;s).rjust(x+(3-(x%3))).gsub(/(\d)(?=\d{3}+(\.\d*)?$)/,'\1,').strip end
end

desc "Display the lines of source code and how many lines were changed in the repository"
task :loc => [:loclines, :locdiff]

desc "Display the lines of source code"
task :loclines do
  require 'find'
  lines = 0
  bytes = 0
  Find.find(*%w(bin lib spec)) do |path|
    Find.prune if path.match(/.*(\b(.hg|.svn|CVS)\b|(.sw.?|.pyc)$)/)
    next if File.directory?(path)
    if path.match(/(\bbin\b|.*\.(env|pl|py|rb|rake|java|sql|ftl|jsp|xml|properties|css|rcss|html|rhtml|erb|po)$)/)
      data = File.read(path)
      bytes += data.size
      lines += data.scan(/^.+$/).size
    end
  end
  puts "Lines: "+lines.commify
  puts "Bytes: "+bytes.commify
end

desc "Display the lines of code changed in the repository"
task :locdiff do
  if File.directory?(".hg")
    puts "%s lines added and removed through SCM operations" % `hg log --no-merges --patch`.scan(/^[+-][^+-].+/).size.commify
  else
    raise NotImplementedError.new("Sorry, this only works for a Mercurial checkout")
  end
end

#---[ misc ]------------------------------------------------------------

desc "Generate documentation"
task :rdoc do
  # Uses Jamis Buck's RDoc template from http://weblog.jamisbuck.org/2005/4/8/rdoc-template
  sh "rdoc --template=jamis --main README.txt --promiscuous --accessor class_inheritable_accessor=R --title 'AutomateIt is an open-source tool for automating the setup and maintenance of UNIX-like systems.' lib README.txt INSTALL.txt USAGE.txt TESTING.txt"
end

desc "Generate documentation for specific files in an endless loop"
task :rdocloop do
  sources_and_targets = {
    "doc/files/USAGE_txt.html" => "USAGE.txt"
  }

  while true
    different = false
    for source, target in sources_and_targets
      if ! File.exists?(target) or (File.exists?(target) and File.mtime(target) > File.mtime(source))
        different = true
        break
      end
    end

    puts "checking %s" % File.mtime(target)
    puts "different" if different

    sh "rdoc --template=jamis --promiscuous --accessor class_inheritable_accessor=R --title 'AutomateIt is an open-source tool for automating the setup and maintenance of UNIX-like systems.' %s" % sources_and_targets.values.join(" ") if different
    sleep 1
  end
end

desc "Profile the specs"
task :prof do
  sh "ruby-prof -f prof.txt `which spec` spec/unit/*.rb"
end

desc "List aliased_methods for inclusion into rdoc"
task :am do
  load_automateit
  AutomateIt.new.instance_eval do
    methods_and_plugins = []
    plugins.values.each{|plugin| plugin.aliased_methods && plugin.aliased_methods.each{|method| methods_and_plugins << [method.to_s, plugin.class.to_s]}}

    for method, plugin in methods_and_plugins.sort_by{|x| x[0]}
      puts "  # * %s -- %s#%s" % [method, plugin, method]
    end
  end
end

#---[ RubyGems ]--------------------------------------------------------

# TODO figure out certificates and signing
# FIXME executables are left behind after uninstall :(
=begin
rm -rf /usr/lib/ruby/gems/*/gems/automateit-*/ /usr/bin/{automateit,field_lookup} /usr/lib/ruby/gems/*/doc/automateit-*/
gem install -y pkg/automateit-*.gem --no-ri --no-rdoc
gem install -y pkg/automateit-*.gem
gem uninstall -a -x automateit
=end
Gem::manage_gems
require 'rake/gempackagetask'
spec = Gem::Specification.new do |s|
  load_automateit
  s.add_dependency("activesupport", ">= 1.4")
  s.add_dependency("open4", ">= 0.9")
  s.author = "Igal Koshevoy"
  s.autorequire = "automateit"
  s.bindir = 'bin'
  s.date = File.mtime('lib/automateit/root.rb')
  s.email = "igal@pragmaticraft.org"
  s.executables = Dir['bin/*'].reject{|t|t.match(/~/)}.map{|t|File.basename(t)}
  s.extra_rdoc_files = %w(README.txt INSTALL.txt USAGE.txt TESTING.txt)
  s.files = FileList["{bin,lib}/**/*"].to_a
  s.has_rdoc = true
  s.homepage = "http://AutomateIt.org/"
  s.name = "automateit"
  s.platform = Gem::Platform::RUBY
  s.rdoc_options << %w(--main README.txt --promiscuous --accessor class_inheritable_accessor=R --title) << 'AutomateIt is an open-source tool for automating the setup and maintenance of UNIX-like systems.' << %w(lib)
  s.require_path = "lib"
  s.rubyforge_project = 'automateit'
  s.summary = "AutomateIt is an open-source tool for automating the setup and maintenance of UNIX-like systems"
  s.test_files = FileList["{spec}/**/*_spec.rb"].to_a
  s.version = AutomateIt::VERSION
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end

desc "Regenerate Gem"
task :regem do
  raise "Can't recreate gems unless a directory with all previous gems is available at ../gems" unless File.directory?("../gems")
  rm_r Dir["pkg/*"]
  mkdir_p "pkg/pub/gems"
  cp "../gems/*.gem", "pkg/pub/gems" unless Dir["../gem/*.gem"].empty?
  Rake::Task[:gem].invoke
  cp Dir["pkg/*.gem"], "pkg/pub/gems"
  sh "cd pkg/pub && ruby ../../misc/index_gem_repository.rb"
end

#===[ fin ]=============================================================
