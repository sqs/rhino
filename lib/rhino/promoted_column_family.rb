module Rhino
  class PromotedColumnFamily
    def self.row=(a_row)
      @row = a_row
    end
    
    def self.row
      @row
    end
    
    def self.column_family=(a_cf); @column_family = a_cf; end
    def self.column_family; @column_family; end
    
    def self.column_family_name=(a_cf_name); @column_family_name = a_cf_name; end
    def self.column_family_name; @column_family_name; end
    
    def self.connect(row, column_family)
      debug("Rhino::PromotedColumnFamily#initialize(#{row.inspect}, #{@column_family.inspect})")
      self.row = row
      self.column_family = column_family
      self.column_family_name = @column_family.column_family_name
      return self
    end
    
    def self.keys
      @column_family.column_names
    end
    
    def self.find(idx)
      if idx.match(/^\d+$/)
        raise "unimplemented"
      else
        if @column_family.column_names.include?(idx)
          new(idx, @row.get_attribute("#{@column_family_name}:#{idx}"))
        else
          raise @column_family.column_names.inspect
          raise "key #{idx.inspect} not found"
        end
      end
    end
    
    def self.belongs_to(containing_class_name)
      debug("#{self.class.name} belongs_to #{containing_class_name}")
      instance_eval { alias_method containing_class_name, :row }
    end
    
    def self.each
      keys.each do |key|
        yield(find(key))
      end
    end
    
    def initialize(key, contents)
      # Don't set these through #key= and #contents= because those go into Rhino::Base and change the data,
      # but this data is coming directly from Rhino::Base and is thus up-to-date already.
      @key = key
      @contents = contents
    end
    
    # The full column name of this object in its containing row.
    def attr_name
      "#{self.class.column_family_name}:#{key}"
    end
    
    def key; @key; end
    def contents; @contents; end
        
    def key=(new_key)
      return if new_key == key
      debug("#{self.class.name}#key= called, going to move value from #{attr_name} to :#{new_key}")
      row.delete_attribute(attr_name)
      @key = new_key
      row.set_attribute(attr_name, contents) # after setting @key, attr_name will have changed to the new full column name
    end
    
    # Sets the contents of this object and updates them in thecontaining model.
    def contents=(new_contents)
      return if new_contents == contents
      debug("#{self.class.name}#contents= called, going to update containing model's #{attr_name}")
      row.set_attribute(attr_name, new_contents)
      @contents = new_contents
    end
    
    def row
      self.class.row
    end
    
    def save
      row.save
    end
  end
end