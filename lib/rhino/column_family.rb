module Rhino
  # A table's column families are represented in Rhino as ColumnFamily objects. While column families are explicitly specified on the model with
  # Rhino::Model.column_family, a family's child columns can change from row to row. A ColumnFamily instance lets you see which child columns,
  # if any, are set on a given row.
  #
  # You can access a row's column families as ColumnFamilies by calling <tt>row.<b>column_family_name</b>_family</tt>, where 
  # <tt><b>column_family_name</b></tt> is the name of a column family you defined on the row.
  #
  # For example, if you have a column family <tt>title:</tt>, the following code will print out the name and contents of each child column:
  #   for column_full_name in row.title_family.column_full_names
  #     puts "Value of column '#{column_full_name}' is '#{row.get_attribute(column_full_name)}'"
  #   end
  # Example output:
  #   Value of column 'title:english' is 'Hello'
  #   Value of column 'title:french' is 'Bonjour'
  #   Value of column 'title:spanish' is 'Hola'
  #
  # === Accessing columns directly
  # If you just want to access the value of a child column and you already know its name, you do not need to use this class to introspect the structure
  # of the row. You can just access the value by calling a method on the row that has the same name as the full name of the column, with underscores 
  # replacing colons.
  #   # to access the title:english column
  #   row.title_english # => 'Hello'
  #   # to access the title:spanish column
  #   row.title_spanish # => 'Hola'
  # You may also access the value of the column with <tt>Rhino::Model#get_attribute(column_name)</tt>.
  #   row.get_attribute('title:english') # => 'Hello'
  class ColumnFamily
    attr_accessor :column_family_name
    
    def initialize(row, column_family_name)
      debug("Rhino::ColumnFamily#initialize(#{row.inspect}, #{column_family_name.inspect})")
      @row = row
      self.column_family_name = column_family_name.to_s
    end
    
    # Returns the full names, including the column family, of each child column. If you only want the second half of the name, with the 
    # family name removed, use +column_names+.
    #   row.column_full_names # => ['title:english', 'title:french', 'title:spanish']
    def column_full_names
      debug("Rhino::ColumnFamily#columns()")
      @row.data.keys.select { |k| k.match(/^#{Regexp.escape(column_family_name)}/)}
    end
    
    # Returns the name of the column not including the name of its family. If you want the full name of the column, including the column
    # family name, use +column_full_names+.
    #   row.column_names # => ['english', 'french', 'spanish']
    # TODO: the #split will cause a problem with column names like links:com.google/search/why:hello (with another colon)
    def column_names
      column_full_names.collect { |column_full_name| column_full_name.split(':')[1] }
    end
  end
end