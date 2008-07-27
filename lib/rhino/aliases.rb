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
        # store new_attribute_name in HBase-style (trailing :)
        new_attribute_name = new_attribute_name.to_s + ':'
        existing_attribute_name = existing_attribute_name.to_s
        unless is_valid_attr_name?(existing_attribute_name)
          raise ArgumentError, "alias_attribute's existing_attribute_name must be a HBase-style column name ('info:email', not :info_email)"
        end
        debug("Rhino::Model.alias_attribute(#{new_attribute_name.inspect}, #{existing_attribute_name.inspect})")
        self.aliases[new_attribute_name] = existing_attribute_name
      end
      
      
      # Returns the column associated with the alias <tt>attr_name</tt>, or <tt>attr_name</tt> if no alias is found.
      #   Page.dealias('email:') # => 'info:email'
      #   Page.dealias('info:signup_date') # => 'info:signup_date'
      def dealias(attr_name)
        #attr_name = attr_name[0..-2] if attr_name[-1]==?: # remove trailing :
        return aliases[attr_name] || attr_name
      end
    end
  end
end