module Rhino
  module Debug
    def debug(str)
      puts "\e[33mDEBUG: #{str}\e[0m" if RHINO_DEBUG
    end

    def highlight(str)
      puts "\e[35m**** #{str}\e[0m" if RHINO_DEBUG
    end

    def hie(obj)
      highlight obj.inspect
      exit!
    end

    def hr
      highlight('-'*40)
    end

    def hi(obj)
      highlight(obj.inspect)
    end
  end
end