require 'spec/rake/spectask'

task :default => :spec

task :spec do
  Spec::Rake::SpecTask.new(:raw_spec) do |t|
    t.rcov = @rcov
    t.spec_files = FileList['spec/unit/**/*_spec.rb']
  end
  Rake::Task[:raw_spec].invoke
end

task "spec:all" do
  Spec::Rake::SpecTask.new(:raw_spec_all) do |t|
    t.rcov = @rcov
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
  sh "find lib spec | egrep -v '.hg|.svn/|/CVS|CVS/|(.sw.?|.pyc)' | egrep '*\.(env|pl|py|rb|rake|java|sql|ftl|jsp|xml|properties|css|rcss|html|rhtml|rake|po)$$' | xargs wc"
end

task :rdoc do
  sh "rdoc --main 'AutomateIt' --exclude 'spec/*'"
end
