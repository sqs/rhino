module Rhino
  module Debug
    def running(str)
      puts "RUNNING: #{str}"
      puts (yield || '').split("\n").collect{ |line| "  #{line}" }.join("\n")
    end
  end
end

def debug(str)
  puts "DEBUG: #{str}"
end