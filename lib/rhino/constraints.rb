module Rhino
  module Constraints
    module ClassMethods
      def self.extended(table)
        @@constraints = {}
      end
    
      def constraints
        @@constraints 
      end
    
      def constraint(name, &logic)
        debug("#{self.class.name} constraint: #{name}")
        self.constraints[name] = logic 
      end
    end
  
    module InstanceMethods
      def check_constraints
        self.class.constraints.each do |name,logic|
          raise ConstraintViolation, "#{self.class.name} failed constraint #{name}" unless logic.call(self)
        end
      end
    end
  end
  class ConstraintViolation < Exception; end
end