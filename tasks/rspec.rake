require 'spec'
require 'spec/rake/spectask'


desc "Run the specs under spec/"
Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ['--colour', "--format", 'profile', '--diff']
  t.spec_files = FileList['spec/**/*_spec.rb']
end