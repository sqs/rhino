module Rhino
  module ActiveRecordImpersonation
    module PromotedColumnFamilyClassMethods
    
    end
  
    module PromotedColumnFamilyInstanceMethods
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