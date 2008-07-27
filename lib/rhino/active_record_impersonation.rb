module Rhino
  module ActiveRecordImpersonation
    module CellClassMethods
    
    end
  
    module CellInstanceMethods
      def new_record?
        true
      end
      
      def id
        0
      end
      
      def type
        self.class.name
      end
    end
  end
end