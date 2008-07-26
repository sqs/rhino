module Rhino
  module Interface
    class HBase
      def initialize(*args)
        raise NotImplementedError
      end
      
      class RowNotFound < Exception

      end
    end
  end
end