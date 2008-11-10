module Rhino
  module Interface
    class Table
      def initialize(*args)
        raise NotImplementedError
      end
      
      def get(*args)
        raise NotImplementedError
      end
      
      def put(*args)
        raise NotImplementedError
      end
      
      def delete(*args)
        raise NotImplementedError
      end
    
      class RowNotFound < Exception

      end
    end
  end
end