module Rhino
  module AttrNames
    module ClassMethods
      def route_attribute_call(method)
        method = method.to_s
        
        # find verb (get or set)
        if method[-1] == ?=
          verb = :set
          method = method[0..-2] # remove trailing "="
        else
          verb = :get
        end
        
        attr_name = determine_attribute_name(method)
        return nil unless attr_name
        
        debug("-> route_attribute_call: attr_name=#{attr_name.inspect}, verb=#{verb}")
        return [verb, attr_name]
      end
      
      def determine_attribute_name(attr_name)
        debug("   determine_attribute_name(#{attr_name.inspect})")
        
        attr_name = attr_name.to_s
        return nil if !attr_name or attr_name.empty?
        return 'timestamp' if attr_name == 'timestamp'
        
        if self.is_valid_attr_name?(attr_name)
          # it is in 'meta:author'-style and thus already a valid attr name, so no need to change it
          return attr_name
        else
          # it is in 'meta_author'-style, so we need to convert it
          attr_name = underscore_name_to_attr_name(attr_name)
          attr_name = self.dealias(attr_name)
          if is_valid_attr_name?(attr_name)
            return attr_name
          else
            # if it is STILL not a valid name, that means it is referring to something we don't know about
            return nil
          end
        end
      end
      
      # Determines whether <tt>attr_name</tt> is a valid column family or column, or a defined alias.
      def is_valid_attr_name?(attr_name)
        return false if attr_name.nil? or attr_name == "" or !attr_name.include?(':')
                
        column_family, column = attr_name.split(':', 2)
        return self.column_families.include?(column_family)
      end
    
      # Converts underscored attribute names to the corresponding attribute name.
      # "meta_author" => "meta:author"
      # "meta:author" => "meta:author"
      # "title" => "title:"
      # "title:" => "title:"
      def underscore_name_to_attr_name(uname)
        uname = uname.to_s
      
        column_family, column = uname.split('_', 2)
        if column
          "#{column_family}:#{column}"
        else
          "#{column_family}:"
        end
      end
    end
  end
end