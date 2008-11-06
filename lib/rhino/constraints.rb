module Rhino
  module Constraints
    def self.included(base)
      puts("Constraints base = #{base.inspect}, self = #{self.inspect}")
      base.extend(ClassMethods)
    end
    
    def check_constraints
      self.class.constraints.each do |name,logic|
        raise ConstraintViolation, "#{self.class.name} failed constraint #{name}" unless logic.call(self)
      end
    end
    
    module ClassMethods
      def constraints
        @constraints ||= {}
      end
    
      def constraint(name, &logic)
        puts "@constraints = #{@constraints.inspect}"
        debug("#{self.class.name} constraint: #{name}")
        constraints[name] = logic 
      end
    end
  end
  class ConstraintViolation < Exception; end
end