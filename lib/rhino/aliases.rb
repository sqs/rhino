module Rhino
  module Aliases
    module ClassMethods
      def self.extended(base)
        @@aliases = {}
      end
      
      def aliases
        @@aliases 
      end
      
      # Creates an alias so that <tt>new_attribute_name</tt> can be used interchangeably with <tt>existing_attribute_name</tt>.
      # For example, with a table like Users(info:) and users' email addresses stored in info:email, the following code would 
      # simplify storing and retrieving email addresses.
      #   alias_attribute :email, 'info:email'
      def alias_attribute(new_attribute_name, existing_attribute_name)
        new_attribute_name = new_attribute_name.to_s
        existing_attribute_name = existing_attribute_name.to_s
        unless is_valid_column_name?(existing_attribute_name)
          raise ArgumentError, "alias_attribute's existing_attribute_name must be a HBase-style column name ('info:email', not :info_email)"
        end
        debug("Rhino::Base.alias_attribute(#{new_attribute_name.inspect}, #{existing_attribute_name.inspect})")
        self.aliases[new_attribute_name] = existing_attribute_name
      end
    end
  end
end