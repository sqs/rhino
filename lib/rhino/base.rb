module Rhino
  # == Specify the structure of your Hbase table
  # To set up the mapping from your Hbase table to Rhino, you must specify the table structure:
  #   class Page < Rhino::Base
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
  class Base
    def initialize(key, data={}, metadata={}, opts={})
      debug("Rhino::Base#initialize(#{key.inspect}, #{data.inspect}, #{metadata.inspect}, #{opts.inspect})")
      self.timestamp = metadata.delete(:timestamp)
      self.requested_columns = metadata.delete(:columns)
      self.opts = {:new_record=>true}.merge(opts)
      self.data = data
      self.key = key
    end
    
    attr_accessor :timestamp
    attr_accessor :requested_columns
    
    def save
      debug("Rhino::Base#save() [key=#{key.inspect}, data=#{data.inspect}, timestamp=#{timestamp.inspect}]")
      put_return_val = self.class.connection.put(key, data, timestamp)
      raise "put failed" unless put_return_val
      if new_record?
        @opts[:new_record] = false
        @opts[:was_new_record] = true
      end
    end
    
    def destroy
      debug("Rhino::Base#destroy() [key=#{key.inspect}]")
      self.class.connection.delete(key, columns)
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
    
    def set_attribute(column_name, value)
      debug("Rhino::Base#set_attribute(#{column_name.inspect}, #{value.inspect})")
      @data[column_name] = value
    end
    
    def get_attribute(column_name)
      debug("Rhino::Base#get_attribute(#{column_name.inspect}) => #{data[column_name].inspect}")
      @data[column_name]
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
    
    # Data that is set here must have HBase-style keys, not underscored keys.
    def data=(some_data)
      debug("Rhino::Base#data=(#{some_data.inspect})")
      @data = {}
      some_data.each do |column_name,val|
        column_name = underscore_name_to_column_name(column_name)
        raise "invalid column name for (#{column_name.inspect},#{val.inspect})" unless self.class.is_valid_column_name?(column_name)
        set_attribute(column_name, val)
      end
      debug("Rhino::Base#data == #{data.inspect}")
      data
    end

    # Attempts to provide access to the data by column name.
    # page.meta_ => page.data['meta:']
    # page.meta_author => page.data['meta:author']
    def method_missing(method, *args)
      debug("Rhino::Base#method_missing(#{method.inspect}, #{args.inspect})")
      method = method.to_s
      is_setter_method = method[-1] == ?=
      column_name = if is_setter_method
        underscore_name_to_column_name(method[0..-2])
      else
        underscore_name_to_column_name(method)
      end
      if self.class.is_valid_column_name?(column_name)
        debug("-> Rhino::Base#method_missing(...): column_name=#{column_name.inspect}")
        if is_setter_method
          set_attribute(column_name, args[0])
        else
          get_attribute(column_name)
        end
      else
        super()
      end
    end
    
    # Converts underscored column names to the corresponding HBase column name.
    # "meta_author" => "meta:author"
    # "title" => "title:"
    # "title:" => "title:"
    def underscore_name_to_column_name(uname)
      #TODO: this breaks if there is a _ in a column name as defined in the database
      uname = uname.to_s
      if uname.match('_')
        uname.gsub('_', ':')
      else
        # don't put another : at the end if one already exists
        uname.match(':') ? uname : "#{uname}:"
      end
    end
    
    def column_name_to_underscore_name(cname)
      cname.to_s.sub(/:$/, '').gsub(':', '_')
    end
    
    class << self
      # Specifies the endpoint URL for the HBase REST API. This URL should end in a slash (e.g., "http://localhost:60010/api").
      # The connection is not actually "established", however, until +connection+ is called.
      def connect(rest_api_endpoint)
        debug("Rhino::Base.connect(#{rest_api_endpoint.inspect})")
        raise "already connected" if @rest_api_endpoint
        @@rest_api_endpoint = rest_api_endpoint
      end
      
      attr_reader :rest_api_endpoint
      
      def connection
        table_endpoint = "#{@@rest_api_endpoint}/#{table_name}"
        @connection ||= HBase::HTable.new(table_endpoint)
      end
      
      attr_accessor :column_families
      
      def column_family(name)
        @column_families ||= []
        name = name.to_s.gsub(':','')
        if @column_families.include?(name)
          debug("column_family '#{name}' already defined for #{self.class.name}")
          @column_families.delete(name)
        end
        @column_families << name
        
        # also define Base#meta_columns and Base#meta_family methods for each column_family
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
      def has_many(column_family_name, cf_class=Rhino::PromotedColumnFamily)
        column_family_name = column_family_name.to_s.gsub(':','')
        define_method(column_family_name) do
          cf_class.connect(self, send("#{column_family_name}_family"))
        end
        # class_eval %Q{
        #           def #{column_family_name}
        #             @#{column_family_name} ||= Rhino::ColumnFamilyProxy.new(self, #{column_family_name}_family)
        #           end
        #         }
      end
      
      def is_valid_column_name?(column_name)
        debug("Rhino::Base.is_valid_column_name?(#{column_name.inspect})")
        return false if column_name.nil? or column_name == ""
        column_family, column = column_name.split(':', 2)
        #TODO: should this check for illegal characters in the column name here as well?
        column_families.include?(column_family)
      end
      
      # Gets the class name, even if the class is within a module (ex: CoolModule::MyThing -> mythings)
      def table_name
        self.name.downcase.split('::')[-1] + 's'
      end
      
      # loads an existing record's data into an object
      def load(key, data, metadata)
        new(key, data, metadata, {:new_record=>false})
      end
      
      def create(key, data={}, metadata={})
        obj = new(key, data, metadata)
        obj.save
        obj
      end
      
      def find(key, find_opts={})
        debug("Rhino::Base.find(#{key.inspect}, #{find_opts.inspect})")
        
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
          data = connection.get(key, :timestamp=>timestamp, :columns=>columns)
          metadata = {:timestamp=>timestamp, :columns=>columns}
          debug("-> found [key=#{key.inspect}, data=#{data.inspect}]")
          load(key, data, metadata)
        rescue HBase::RowNotFound
          return nil
        end
      end
    end
  end
end