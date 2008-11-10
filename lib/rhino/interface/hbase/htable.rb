module Rhino
  module Interface
    class HTable
      def initialize(*args)
        raise NotImplementedError
      end
      
      def name
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
      
      def name
        raise NotImplementedError
      end
      
      def name
        raise NotImplementedError
      end
      
      def name
        raise NotImplementedError
      end
    
      class RowNotFound < Exception

      end
    end
  end
end