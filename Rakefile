require 'spec/rake/spectask'

task :default => :spec

task :spec do
  Spec::Rake::SpecTask.new(:raw_spec) do |t|
    t.rcov = @rcov
    t.spec_files = FileList['spec/unit/**/*_spec.rb']
  end
  Rake::Task[:raw_spec].invoke
end

task :rcov do
  @rcov = true
  Rake::Task[:spec].invoke
end
