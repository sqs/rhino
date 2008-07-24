module Rhino
  class PromotedColumnFamily
    def self.connect(row, column_family)
      debug("Rhino::PromotedColumnFamily#initialize(#{row.inspect}, #{@column_family.inspect})")
      @row = row
      @column_family = column_family
      @column_family_name = @column_family.column_family_name
      return self
    end
    
    def self.keys
      @column_family.column_names
    end
    
    def self.[](idx)
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
    
    attr_accessor :key, :contents
    def initialize(key, contents)
      self.key = key
      self.contents = contents
    end
  end
end