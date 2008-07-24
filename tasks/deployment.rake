require 'rake/rdoctask'

Rake::RDocTask.new { |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "Rhino - Ruby Hbase ORM"
  rdoc.options << '--line-numbers' << '--inline-source' << '-A cattr_accessor=object'
  rdoc.options << '--charset' << 'utf-8'
  rdoc.template = "#{ENV['template']}.rb" if ENV['template']
  rdoc.rdoc_files.include('README', 'CHANGELOG')
  rdoc.rdoc_files.include('lib/**/*.rb')
  #rdoc.rdoc_files.exclude('lib/active_record/vendor/*')
  #rdoc.rdoc_files.include('dev-utils/*.rb')
}

__END__
# old task
desc "build rdoc documentation"
task :doc do
  sh "rdoc --all --title 'Rhino Documentation' --force-update --inline-source --main README README lib/ MIT-LICENSE CHANGELOG"
end