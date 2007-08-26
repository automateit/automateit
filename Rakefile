require 'spec/rake/spectask'

task :default => :spec

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

task "spec" do
  target = ENV['F'] || ENV['FILE'] || 'spec/unit/**/*_spec.rb'
  specify(target)
end

task "rcov" do
  @rcov = true
  Rake::Task["spec"].invoke
end

task "spec:all" do
  specify('spec/unit/**/*_spec.rb', 'spec/functional/**/*_spec.rb', 'spec/integration/**/*_spec.rb')
end

task "rcov:all" do
  @rcov = true
  Rake::Task["spec:all"].invoke
end

task "verbose" do
  ENV["SPEC_OPTS"] = "-fs"
end

#---[ calculate LOC ]---------------------------------------------------

class Numeric
  def commify() (s=self.to_s;x=s.length;s).rjust(x+(3-(x%3))).gsub(/(\d)(?=\d{3}+(\.\d*)?$)/,'\1,').strip end
end

task :loc => [:loclines, :locdiff] do
end

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

task :locdiff do
  if File.directory?(".hg")
    puts "%s lines added and removed through SCM operations" % `hg log --no-merges --patch`.scan(/^[+-][^+-].+/).size.commify
  else
    raise NotImplementedError.new("Sorry, this only works for a Mercurial checkout")
  end
end

#---[ misc ]------------------------------------------------------------

task :rdoc do
  sh "rdoc --main 'AutomateIt::Interpreter' lib --promiscuous --title 'Documentation for AutomateIt, an open-source tool for automating the setup and maintenance of UNIX-like systems.'"
end

task :prof do
  sh "ruby-prof -f prof.txt `which spec` spec/unit/*.rb"
end

#===[ fin ]=============================================================
