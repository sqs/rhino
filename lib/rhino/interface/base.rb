module Rhino
  module Interface
    class Base
      def initialize(*args)
        raise NotImplementedError
      end
      
      class RowNotFound < Exception

      end
    end
  end
end