require 'spec/rake/spectask'

task :default => :spec

task :spec do
  Spec::Rake::SpecTask.new(:raw_spec) do |t|
    t.rcov = @rcov
    t.rcov_opts = ['--exclude', 'spec']
    t.spec_files = FileList['spec/unit/**/*_spec.rb']
  end
  Rake::Task[:raw_spec].invoke
end

task "spec:all" do
  Spec::Rake::SpecTask.new(:raw_spec_all) do |t|
    t.rcov = @rcov
    t.rcov_opts = ['--exclude', 'spec']
    t.spec_files = FileList[
      'spec/unit/**/*_spec.rb',
      'spec/functional/**/*_spec.rb',
      'spec/integration/**/*_spec.rb'
    ]
  end
  Rake::Task[:raw_spec_all].invoke
end

task :rcov do
  @rcov = true
  Rake::Task[:spec].invoke
end

task "rcov:all" do
  @rcov = true
  Rake::Task["spec:all"].invoke
end

task :loc do
  require 'find'
  lines = 0
  bytes = 0
  Find.find(*%w(lib spec)) do |path|
    Find.prune if path.match(/.*(\b(.hg|.svn|CVS)\b|(.sw.?|.pyc)$)/)
    if path.match(/.*\.(env|pl|py|rb|rake|java|sql|ftl|jsp|xml|properties|css|rcss|html|rhtml|erb|po)$/)
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

task :rdoc do
  sh "rdoc --main 'AutomateIt' --exclude 'spec/*'"
end

task :prof do
  sh "ruby-prof -f prof.txt `which spec` spec/unit/*.rb"
end

class Numeric
  def commify() (s=self.to_s;x=s.length;s).rjust(x+(3-(x%3))).gsub(/(\d)(?=\d{3}+(\.\d*)?$)/,'\1,').strip end
end
