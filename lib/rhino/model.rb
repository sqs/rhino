require 'rubygems'
require 'active_support/inflector'

module Rhino
  # == Specify the structure of your Hbase table
  # To set up the mapping from your Hbase table to Rhino, you must specify the table structure:
  #   class Page < Rhino::Model
  #     column_family :title
  #     column_family :contents
  #     column_family :links
  #     column_family :meta
  #   end
  #
  # == Creating rows
  # Each row must have a row key.
  #   page = Page.new('yahoo.com') # row key is 'yahoo.com'
  #   page.title = "Yahoo!"
  #   page.save
  #
  # You also can specify the data as a hash in the second argument to +new+.
  #   page = Page.new('google.com', {:title=>'Google'})
  #   page.contents = "<h1>Welcome to Google</h1>"
  #   page.save
  #
  # Or you can just save the row to the database immediately.
  #   page = Page.create('microsoft.com', {:title=>'Microsoft', :contents=>'<h1>Hello, we are Microsoft!'})
  #
  # == Retrieving and updating existing rows
  # Currently, you can only retrieve existing rows by key or by both key and timestamp (see below).
  #   page = Page.get('yahoo.com')
  #   page.title = "Yahoo! version 2.0"
  #   page.save
  # 
  # == Setting and retrieving by timestamp
  # When saving rows, you can set a timestamp.
  #   a_week_ago = Time.now - 7 * 24 * 3600
  #   Page.create('google.com', {:title=>'Google, a week ago!'}, {:timestamp=>a_week_ago})
  #
  # When retrieving rows, you can specify an optional timestamp to retrieve a certain version of a row.
  #
  #   a_week_ago = Time.now - 7 * 24 * 3600
  #   a_month_ago = Time.now - 30 * 24 * 3600
  #   
  #   newer_page = Page.create('google.com', {:title=>'newer google'}, {:timestamp=>a_week_ago})
  #   older_page = Page.create('google.com', {:title=>'older google'}, {:timestamp=>a_month_ago})
  #   
  #   # now you can get() by the timestamps you just set
  #   Page.get('google.com', :timestamp=>a_week_ago).title # => "newer google"
  #   Page.get('google.com', :timestamp=>a_month_ago).title # => "older google"
  #
  # If no timestamp is specified when retrieving rows, the most recent row will be returned.
  # 
  #   page = Page.get('google.com')
  #   page.title # => 'newer google'
  #
  # If a timestamp is specified that does not match any rows of that key in the database, <tt>nil</tt> is returned.
  #
  #   three_days_ago = Time.now - 3 * 24 * 3600
  #   Page.get('google.com', :timestamp=>three_days_ago) # => nil
  #
  # == Accessing data on rows
  # A row's attributes may be accessed or written as follows.
  #
  # For column families:
  #
  #   page.title # returns value of title: column
  #   page.title = 'Welcome!' # sets value of title: column
  #
  # For child columns (columns underneath a column family):
  #
  #   page.meta_author # returns value of meta:author column
  #   page.meta_language = 'en-US' # sets value of meta:language column
  class Model
    # extend Rhino::Constraints::ClassMethods
    # include Rhino::Constraints::InstanceMethods
    
    extend Rhino::Aliases::ClassMethods
    extend Rhino::AttrNames::ClassMethods
    
    def initialize(key, data={}, opts={})
      debug("Model#initialize(#{key.inspect}, #{data.inspect}, #{opts.inspect})")
      self.data = data
      self.key = key
      self.opts = {:new_record=>true}.merge(opts)
    end
        
    def save(with_timestamp=nil)
      debug("Model#save() [key=#{key.inspect}, data=#{data.inspect}, timestamp=#{timestamp.inspect}]")
      check_constraints() if respond_to?(:check_constraints)
      
      # we need to delete data['timestamp'] here or else it will be written to hbase as a column (and will
      # cause an error since no 'timestamp' column exists)
      # but we also want to invalidate the timestamp since saving the row will give it a new timestamp,
      # so this accomplishes both
      data.delete('timestamp')
      
      self.class.table.put(key, data, with_timestamp)
      if new_record?
        @opts[:new_record] = false
        @opts[:was_new_record] = true
      end
      return true
    end
    
    def destroy
      debug("Model#destroy() [key=#{key.inspect}]")
      self.class.table.delete_row(key)
    end
    
    def data
      @data
    end
    
    def key
      @key
    end
    
    def new_record?
      @opts[:new_record]
    end
    
    def was_new_record?
      @opts[:was_new_record] || false
    end
    
    def set_attribute(attr_name, value)
      debug("Model#set_attribute(#{attr_name.inspect}, #{value.inspect})")
      @data[attr_name] = value
    end
    
    def get_attribute(attr_name)
      debug("Model#get_attribute(#{attr_name.inspect}) => #{data[attr_name].inspect}")
      @data[attr_name]
    end
    
    # If <tt>attr_name</tt> is a column family, nulls out the value. If <tt>attr_name</tt> is a column, removes the column from the row.
    def delete_attribute(attr_name)
      debug("Model#delete_attribute(#{attr_name.inspect})")
      set_attribute(attr_name, nil)
    end
    
    def columns
      @data.keys
    end
    
    def data
      @data
    end
    
    # Returns true if the +comparison_object+ is the same object; or is of the same type, has the same key and data, and is not a new record.
    def ==(comparison_object)
      comparison_object.equal?(self) ||
        (comparison_object.instance_of?(self.class) &&
          comparison_object.data == data &&
          comparison_object.key == key &&
          !comparison_object.new_record?)
    end
    
    def key=(a_key)
      @key = a_key
    end
    
    def timestamp
      @data['timestamp']
    end
    
    def timestamp=(a_timestamp)
      @data['timestamp'] = a_timestamp
    end
    
    private
    
    attr_reader :opts
    def opts=(some_opts)
      @opts = some_opts
    end
    
    # Data that is set here must have HBase-style keys (like {'meta:author'=>'John'}), not underscored keys {:meta_author=>'John'}.
    def data=(some_data)
      debug("Model#data=(#{some_data.inspect})")
      @data = {}
      some_data.each do |data_key,val|
        attr_name = self.class.determine_attribute_name(data_key)
        raise(ArgumentError, "invalid attribute name for (#{data_key.inspect},#{val.inspect})") unless attr_name
        set_attribute(attr_name, val)
      end
      debug("Model#data == #{data.inspect}")
      data
    end

    # Attempts to provide access to the data by attribute name.
    #   page.meta # => page.data['meta:']
    #   page.meta_author # => page.data['meta:author']
    def method_missing(method, *args)
      debug("Model#method_missing(#{method.inspect}, #{args.inspect})")
      if call_data = self.class.route_attribute_call(method)
        verb, attr_name = *call_data
        case verb
        when :get
          get_attribute(attr_name)
        when :set
          set_attribute(attr_name, args[0])
        end
      else
        super # pass it on to Object#method_missing, which will raise NoMethodError
      end
    end    
    
    #################
    # CLASS METHODS #
    #################
    
    def self.connect(host, port, adapter = Rhino::HBaseThriftInterface)
      debug("Model.connect(#{host.inspect}, #{port.inspect}, #{adapter.inspect})")
      raise "already connected" if self.connected?
      @@adapter = adapter
      @@conn = adapter::Base.new(host, port)
      @@column_families = []
    end
        
    # Returns true if connected to the database, and false otherwise.
    def self.connected?
      return false if not self.class_variable_defined? :@@conn
      @@conn != nil
    end
    
    #returns the shared connection. throws if not connected
    def self.connection
      raise "not connected" if not self.connected?
      @@conn
    end
    
    # Returns the table interface.
    def self.table
      @table ||= @@adapter::Table.new(connection, table_name)
    end
    
    def self.column_families
      @@column_families
    end
    
    def self.column_family(name)
      name = name.to_s.gsub(':','')
      @@column_families ||= []
      if @@column_families.include?(name)
        debug("column_family '#{name}' already defined for #{self.class.name}")
        @@column_families.delete(name)
      end
      @@column_families << name
      
      # also define Model#meta_columns and Model#meta_family methods for each column_family
      class_eval %Q{
        def #{name}_family
          @#{name}_family ||= Rhino::ColumnFamily.new(self, :#{name})
        end
        
        def #{name}_column_names
          #{name}_family.column_names
        end
        
        def #{name}_column_full_names
          #{name}_family.column_full_names
        end
      }
    end
    
    # Specifying that a model <tt>has_many :links</tt> overwrites the Model#links method to
    # return a proxied array of columns underneath the <tt>links:</tt> column family.
    def self.has_many(column_family_name, cell_class=Rhino::Cell)
      column_family_name = column_family_name.to_s.gsub(':','')
      define_method(column_family_name) do
        column_family = send("#{column_family_name}_family")
        @cells_proxies ||= {}
        @cells_proxies[column_family_name] ||= Rhino::CellsProxy.new(self, column_family, cell_class)
      end
    end
    
    # Determines the table name, even if the model class is within a module (ex: CoolModule::MyThing -> mythings).
    # You can override this by defining the <tt>table_name</tt> class method on your model class.
    def self.table_name
      self.name.downcase.split('::')[-1].pluralize
    end
    
    # loads an existing record's data into an object
    def self.load(key, data)
      new(key, data, {:new_record=>false})
    end
    
    def self.create(key, data={})
      obj = new(key, data)
      obj.save(data[:timestamp])
      obj
    end
    
    # Scans the table with +opts+ (if provided) and returns an array of each row that is returned by the scanner.
    # See +scan+ for options.
    def self.get_all(opts={})
      scan(opts).collect
    end
    
    # Returns a Scanner that will iterate through the rows, according to the arguments.
    # ==== Options
    # * <tt>:start_row => 'row key'</tt> - Return only rows whose keys, in lexical order, occur at or after this row key.
    #   The row specified by the key supplied in <tt>:start_row</tt>, if it exists, will be returned.
    #   This option can be combined with <tt>:stop_row</tt>.
    # * <tt>:stop_row => 'row key'</tt> - Return only rows whose keys, in lexical order, occur before this row key.
    #   The row specified by the key supplied in <tt>:stop_row</tt>, if it exists, will NOT be returned.
    #   This option can be combined with <tt>:start_row</tt>.
    # ==== Notes
    # Note that <tt>:start_row</tt> is inclusive of the start row key, while <tt>:stop_row</tt> is exclusive.
    # For example, with row keys A, B, and C, starting at B would return B and C. If the stop row were C, however,
    # the Scanner would only return A and B.
    def self.scan(opts={})
      Rhino::Scanner.new(self, opts)
    end
    
    def self.get(key, get_opts={})
      debug("Model.get(#{key.inspect}, #{get_opts.inspect})")
      
      # handle opts
      get_opts.keys.each { |fo_key| raise ArgumentError, "invalid key for get opts: #{fo_key.inspect}" unless %w(columns timestamp).include?(fo_key.to_s) }
      raise ArgumentError, "columns key for get opts is unimplemented" if get_opts.keys.include?(:columns)
      timestamp = get_opts[:timestamp]
      
      # get the row
      begin
        data = table.get(key, :timestamp=>timestamp)
        debug("-> found [key=#{key.inspect}, data=#{data.inspect}]")
        load(key, data)
      rescue Rhino::Interface::Table::RowNotFound
        return nil
      end
    end
    
    def self.delete_all
      table.delete_all_rows
    end
  end
end