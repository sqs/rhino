namespace :hbase do
  HBASE_DIR = '~/src/hbase-0.18.1'
  
  desc "start hbase & thrift"
  task :start do
    sh "#{HBASE_DIR}/bin/start-hbase.sh"
    sleep 4
    sh "#{HBASE_DIR}/bin/hbase-daemon.sh start thrift"
  end
  
  desc "stop hbase & thrift"
  task :stop do
    sh "#{HBASE_DIR}/bin/hbase-daemon.sh stop thrift"
    sh "#{HBASE_DIR}/bin/stop-hbase.sh"
  end
  
  desc "restart hbase & thrift"
  task :restart=>[:stop, :start]
  
  desc "open hbase shell"
  task :shell do
    sh "#{HBASE_DIR}/bin/hbase shell"
  end
  
  desc "empty db"
  task :clear do
    sh %Q{echo "disable 'pages';drop 'pages';create 'pages', 'title', 'contents', 'links', 'meta', 'images'"|#{HBASE_DIR}/bin/hbase shell}
  end
end

desc "restart hbase"
task :restart=>[:stop, :start]

desc "start hbase"
task :start=>['hbase:start']

desc "stop hbase"
task :stop=>['hbase:stop']

desc "clear hbase"
task :clear=>['hbase:clear']