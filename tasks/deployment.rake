namespace "doc" do
  desc "Generate RDoc docs"
  task :generate do
    # Using rake/rdoctask invoked old rdoc 1.x for some reason, but this invokes rdoc 2.x
    sh "rdoc --all --title 'Rhino - Ruby HBase ORM' --line-numbers --inline-source --force-update --all --charset utf-8 --main README README lib/"
  end

  desc "Upload docs to site"
  task :upload do
    sh "tar czfv rhino-rdoc.tgz doc/"
    puts
    puts "Going to upload..."
    puts
    sh "scp rhino-rdoc.tgz cardinal.stanford.edu:WWW/rhino/"
    sh "ssh cardinal.stanford.edu 'cd WWW/rhino;tar xzfv rhino-rdoc.tgz'"
    sh "rm rhino-rdoc.tgz"
    puts
    puts "Upload complete"
  end
  
  desc "Generate & upload"
  task :update=>[:generate, :upload]
end


