module Rhino
  module Debug
    def running(str)
      puts "RUNNING: #{str}"
      puts (yield || '').split("\n").collect{ |line| "  #{line}" }.join("\n")
    end
  end
end

def debug(str)
  puts "\e[33mDEBUG: #{str}\e[0m"
end

def highlight(str)
  puts "\e[35m**** #{str}\e[0m"
end

def hie(obj)
  highlight obj.inspect
  exit!
end

def hr
  highlight('-'*40)
end