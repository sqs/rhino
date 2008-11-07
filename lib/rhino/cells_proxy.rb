class Rhino::CellsProxy
  include Enumerable
  
  attr_accessor :row, :column_family, :column_family_name, :cell_class
  
  def initialize(row, column_family, cell_class)
    debug("CellsProxy#initialize(row, #{column_family}, #{cell_class})")
    self.row = row
    self.column_family = column_family
    self.column_family_name = column_family.column_family_name
    self.cell_class = cell_class
  end
  
  def keys
    @column_family.column_names
  end
  
  # Instantiate a new cell object pointing to this proxy's row.
  def new_cell(key, contents)
    cell_class.new(key, contents, self)
  end
  
  def get(key)
    # consider nil values as nonexistent, because they could refer to cells that will be deleted on the next #save
    # but haven't (a nil value is the marker that it will be deleted)
    if val = @row.get_attribute("#{column_family_name}:#{key}")
      new_cell(key, val)
    else
      return nil
    end
  end
  
  # Creates cells in the database from the specified <tt>keys_and_contents</tt>, which is a hash in the form:
  #   {'com.yahoo'=>'Yahoo', 'com.apple.www'=>'Apple'}
  # and saves the cells.
  # Returns an array of the cell objects.
  def create_multiple(keys_and_contents)
    keys_and_contents.collect do |key,contents|
      create(key, contents)
    end
  end
  
  # Adds a cell using Cell.add(...) and then saves the row to the database.
  # Returns the cell object.
  def create(key, contents, timestamp=nil)
    cell = add(key, contents)
    cell.save(timestamp)
    return cell
  end
  
  def add(key, contents)
    cell = new_cell(key, contents)
    cell.write
    return get(key)
  end
  
  def each
    keys.each do |key|
      yield(get(key))
    end
  end
end
