module Rhino
  class Cell
    extend Enumerable
    
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
      debug("Rhino::Cell#initialize(#{row.inspect}, #{@column_family.inspect})")
      self.row = row
      self.column_family = column_family
      self.column_family_name = @column_family.column_family_name
      return self
    end
    
    def self.keys
      @column_family.column_names
    end
    
    def self.get(key)
      if key.match(/^\d+$/)
        raise "get cell by index is unimplemented"
      else
        # consider nil values as nonexistent, because they could refer to cells that will be deleted on the next #save
        # but haven't (a nil value is the marker that it will be deleted)
        if val = @row.get_attribute("#{@column_family_name}:#{key}")
          new(key, val)
        else
          return nil
        end
      end
    end
    
    # Adds multiple cells using Cell.add_multiple(...) and then saves the row to the database.
    # Returns an array of the cell objects.
    def self.create_multiple(keys_and_contents)
      cells = add_multiple(keys_and_contents)
      row.save
      return cells
    end
    
    # Creates cells in the database from the specified <tt>keys_and_contents</tt>, which is a hash in the form:
    #   {'com.yahoo'=>'Yahoo', 'com.apple.www'=>'Apple'}
    # Returns an array of the cell objects.
    def self.add_multiple(keys_and_contents)
      return keys_and_contents.collect do |key,contents|
        create(key, contents)
      end
    end
    
    # Adds a cell using Cell.add(...) and then saves the row to the database.
    # Returns the cell object.
    def self.create(key, contents)
      cell = add(key, contents)
      row.save
      return cell
    end
    
    # Creates a cell in the database under this column family with the column name given in <tt>key</tt> and the supplied contents.
    # Returns the cell object.
    def self.add(key, contents)
      cell = new(key, contents)
      cell.write
      return get(key)
    end
    
    
    def self.belongs_to(containing_class_name)
      debug("#{self.class.name} belongs_to #{containing_class_name}")
      # for the Page example, this would define Cell#page
      define_method(containing_class_name) { self.class.row }
    end
    
    def self.each
      keys.each do |key|
        yield(get(key))
      end
    end
    
    def initialize(key, contents)
      # Don't set these through #key= and #contents= because those go into Rhino::Model and change the data,
      # but this data is coming directly from Rhino::Model and is thus up-to-date already.
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
      debug("#{self.class.name}#key= called, going to move value from #{attr_name} to :#{new_key}")
      self.class.row.delete_attribute(attr_name)
      @key = new_key
      # after setting @key, attr_name will have changed to the new full column name, so #write will write the right cell
      write 
    end
    
    # Sets the contents of this object and updates them in the containing model.
    def contents=(new_contents)
      debug("#{self.class.name}#contents= called, going to update containing model's #{attr_name}")
      @contents = new_contents
      write
    end
    
    # Writes this cell's key and contents to its row object, but does not save this row object.
    def write
      self.class.row.set_attribute(attr_name, contents)
    end
    
    def save
      self.class.row.save
    end
    
    def destroy
      self.class.row.delete_attribute(attr_name)
      self.class.row.save
    end
  end
end