module Rhino
  class PromotedColumnFamily
    def self.row=(a_row)
      @row = a_row
    end
    
    def self.row
      @row
    end
    
    def self.connect(row, column_family)
      debug("Rhino::PromotedColumnFamily#initialize(#{row.inspect}, #{@column_family.inspect})")
      self.row = row
      @column_family = column_family
      @column_family_name = @column_family.column_family_name
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
    
    attr_accessor :key, :contents
    def initialize(key, contents)
      self.key = key
      self.contents = contents
    end
    
    def row
      self.class.row
    end
  end
end