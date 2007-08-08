require 'spec/rake/spectask'

task :default => :spec

Spec::Rake::SpecTask.new(:spec) do |t|
  #IK# t.rcov = true
  t.spec_files = FileList['spec/unit/**/*_spec.rb']
end
