module Rhino
  # == Specify the structure of your Hbase table
  # To set up the mapping from your Hbase table to Rhino, you must specify the table structure:
  #   class Page < Rhino::Table
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
  #   page = Page.find('yahoo.com')
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
  #   # now you can find() by the timestamps you just set
  #   Page.find('google.com', :timestamp=>a_week_ago).title # => "newer google"
  #   Page.find('google.com', :timestamp=>a_month_ago).title # => "older google"
  #
  # If no timestamp is specified when retrieving rows, the most recent row will be returned.
  # 
  #   page = Page.find('google.com')
  #   page.title # => 'newer google'
  #
  # If a timestamp is specified that does not match any rows of that key in the database, <tt>nil</tt> is returned.
  #
  #   three_days_ago = Time.now - 3 * 24 * 3600
  #   Page.find('google.com', :timestamp=>three_days_ago) # => nil
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
  class Table
    extend Rhino::Constraints::ClassMethods
    include Rhino::Constraints::InstanceMethods
    
    extend Rhino::Aliases::ClassMethods
    
    def initialize(key, data={}, metadata={}, opts={})
      debug("Rhino::Table#initialize(#{key.inspect}, #{data.inspect}, #{metadata.inspect}, #{opts.inspect})")
      self.timestamp = metadata.delete(:timestamp)
      self.requested_columns = metadata.delete(:columns)
      self.opts = {:new_record=>true}.merge(opts)
      self.data = data
      self.key = key
    end
    
    attr_accessor :timestamp
    attr_accessor :requested_columns
    
    def save
      debug("Rhino::Table#save() [key=#{key.inspect}, data=#{data.inspect}, timestamp=#{timestamp.inspect}]")
      check_constraints()
      self.class.htable.put(key, data, new_record?, timestamp)
      if new_record?
        @opts[:new_record] = false
        @opts[:was_new_record] = true
      end
      return true
    end
    
    def destroy
      debug("Rhino::Table#destroy() [key=#{key.inspect}]")
      self.class.htable.delete(key)
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
    
    def set_attribute(attr_name, value)
      debug("Rhino::Table#set_attribute(#{attr_name.inspect}, #{value.inspect})")
      attr_name = self.class.dealias(attr_name)
      @data[attr_name] = value
    end
    
    def get_attribute(attr_name)
      debug("Rhino::Table#get_attribute(#{attr_name.inspect}) => #{data[attr_name].inspect}")
      attr_name = self.class.dealias(attr_name)
      @data[attr_name]
    end
    
    # If <tt>attr_name</tt> is a column family, nulls out the value. If <tt>attr_name</tt> is a column, removes the column from the row.
    def delete_attribute(attr_name)
      debug("Rhino::Table#delete_attribute(#{attr_name.inspect})")
      attr_name = self.class.dealias(attr_name)
      # TODO: this has problems if the column name has a : in it other than between c.f. and column name
      is_column_family = !attr_name[0..-2].include?(':')
      if is_column_family
        set_attribute(attr_name, nil)
      else
        # TODO: this only sets it to nil, it doesn't actually remove the column. that's because I need to find a way to signal
        # that the column should be removed, but @data.delete(attr_name) will also mean that #save doesn't update it, since
        # it isn't in @data.keys.
        # TODO: test this all - how does setting nil work with versioning (old versions still exist, I presume, etc.)
        set_attribute(attr_name, nil)
      end
    end
    
    def columns
      @data.keys
    end
    
    def data
      @data
    end
    
    private
    
    attr_reader :opts
    def opts=(some_opts)
      @opts = some_opts
    end
    
    def key=(a_key)
      @key = a_key
    end
    
    # Data that is set here must have HBase-style keys (like {'meta:author'=>'John'}), not underscored keys {:meta_author=>'John'}.
    def data=(some_data)
      debug("Rhino::Table#data=(#{some_data.inspect})")
      @data = {}
      some_data.each do |attr_name,val|
        attr_name = underscore_name_to_attr_name(attr_name)
        raise "invalid attribute name for (#{attr_name.inspect},#{val.inspect})" unless self.class.is_valid_attr_name?(attr_name)
        set_attribute(attr_name, val)
      end
      debug("Rhino::Table#data == #{data.inspect}")
      data
    end

    # Attempts to provide access to the data by attribute name.
    #   page.meta_ # => page.data['meta:']
    #   page.meta_author # => page.data['meta:author']
    # TODO: should we keep using the trailing underscore methods? (like meta_)
    def method_missing(method, *args)
      debug("Rhino::Table#method_missing(#{method.inspect}, #{args.inspect})")
      method = method.to_s
      is_setter_method = method[-1] == ?=
      attr_name = if is_setter_method
        underscore_name_to_attr_name(method[0..-2])
      else
        underscore_name_to_attr_name(method)
      end
      
      if self.class.is_valid_attr_name?(attr_name)
        debug("-> Rhino::Table#method_missing(...): attr_name=#{attr_name.inspect}")
        if is_setter_method
          set_attribute(attr_name, args[0])
        else
          get_attribute(attr_name)
        end
      else
        raise ArgumentError, "method_missing(#{method.inspect}, #{args.inspect})"
      end
    end
    
    # Converts underscored attribute names to the corresponding attribute name.
    # "meta_author" => "meta:author"
    # "title" => "title:"
    # "title:" => "title:"
    def underscore_name_to_attr_name(uname)
      #TODO: this breaks if there is a _ in a column name as defined in the database
      uname = uname.to_s
      if uname.match('_')
        uname.gsub('_', ':')
      else
        # don't put another : at the end if one already exists
        uname.match(':') ? uname : "#{uname}:"
      end
    end
    
    
    
    
    #################
    # CLASS METHODS #
    #################
    
    
    # Specifies the endpoint URL for the HBase REST API. This URL should end in a slash (e.g., "http://localhost:60010/api").
    # The connection is not actually "established", however, until +connection+ is called.
    def Table.connect(host, port)
      debug("Rhino::Table.connect(#{host.inspect}, #{port.inspect})")
      raise "already connected" if hbase
      @hbase = Rhino::ThriftInterface::HBase.new(host, port)
    end
    
    # Returns true if connected to the database, and false otherwise.
    def Table.connected?
      @hbase != nil
    end
    
    # Returns the connection to HBase. The connection to HBase is shared across all models and is stored in Rhino::Table,
    # so models retrieve it from Rhino::Table.
    def Table.hbase
      # uses self.name instead of self.class because in class methods, self.class==Object and self.name=="Rhino::Table"
      if self.name == "Rhino::Table"
        @hbase
      else
        Rhino::Table.hbase
      end
    end
    
    # Returns the HTable interface.
    def Table.htable
      @htable ||= Rhino::ThriftInterface::HTable.new(hbase, table_name)
    end
    
    def Table.column_families; @column_families ||= []; end
    
    def Table.column_family(name)
      name = name.to_s.gsub(':','')
      if column_families.include?(name)
        debug("column_family '#{name}' already defined for #{self.class.name}")
        column_families.delete(name)
      end
      column_families << name
      
      # also define Table#meta_columns and Table#meta_family methods for each column_family
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
    def Table.has_many(column_family_name, cf_class=Rhino::Cell)
      column_family_name = column_family_name.to_s.gsub(':','')
      define_method(column_family_name) do
        cf_class.connect(self, send("#{column_family_name}_family"))
      end
    end
    
    # Determines whether <tt>attr_name</tt> is a valid column family or column, or a defined alias.
    def Table.is_valid_attr_name?(attr_name)
      debug("Rhino::Table.is_valid_attr_name?(#{attr_name.inspect})")
      return false if attr_name.nil? or attr_name == ""
      attr_name = dealias(attr_name)
                
      column_family, column = attr_name.split(':', 2)
      #TODO: should this check for illegal characters in the column name here as well?
      return column_families.include?(column_family)
    end
    
    # Gets the class name, even if the class is within a module (ex: CoolModule::MyThing -> mythings)
    def Table.table_name
      self.name.downcase.split('::')[-1] + 's'
    end
    
    # loads an existing record's data into an object
    def Table.load(key, data, metadata)
      new(key, data, metadata, {:new_record=>false})
    end
    
    def Table.create(key, data={}, metadata={})
      obj = new(key, data, metadata)
      obj.save
      obj
    end
    
    def Table.find_or_create(key, data={}, metadata={})
      find(key) || create(key, data, metadata)
    end
    
    def Table.find(key, find_opts={})
      debug("Rhino::Table.find(#{key.inspect}, #{find_opts.inspect})")
      
      # handle opts
      find_opts.keys.each { |fo_key| raise ArgumentError, "invalid key for find opts: #{fo_key.inspect}" unless %w(columns timestamp).include?(fo_key.to_s) }
      raise ArgumentError, "columns key for find opts is unimplemented" if find_opts.keys.include?(:columns)
      timestamp = find_opts[:timestamp]
      columns = if find_opts.include?(:columns)
        # convert like: %w(col1 col2 col3) => "col1;col2;col3"
        find_opts.delete[:columns].collect(&:to_s).join(';')
      else
        nil
      end
      
      # find the row
      begin
        data = htable.get(key, :timestamp=>timestamp, :columns=>columns)
        metadata = {:timestamp=>timestamp, :columns=>columns}
        debug("-> found [key=#{key.inspect}, data=#{data.inspect}]")
        load(key, data, metadata)
      rescue Rhino::Interface::HTable::RowNotFound
        return nil
      end
    end
    
    def Table.delete_all
      htable.delete_all
    end
  end
end