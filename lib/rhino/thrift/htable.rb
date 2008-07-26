module Rhino
  module ThriftInterface
    class HTable < Rhino::Interface::HTable
      attr_reader :hbase, :table_name
      
      def initialize(hbase, table_name, opts={})
        @hbase = hbase
        @table_name = table_name
        @opts = opts
      end
      
      def column_families
        determine_column_families unless @opts[:column_families]
        @opts[:column_families]
      end
      
      DEFAULT_GET_OPTIONS = {:timestamp => nil, :columns => nil}
    
      def get(key, options = {})
        opts = DEFAULT_GET_OPTIONS.merge(options)
        debug("#{self.class.name}#get(#{key.inspect}, #{options.inspect})")
      
        columns = Array(opts.delete(:columns)).compact

        # TODO: do argument checking of timestamp - must be an integer (or nil, in which case it is not used)
        timestamp = opts.delete(:timestamp)
        timestamp = timestamp.to_i if timestamp
        
        data = if timestamp
          hbase.getRowTs(table_name, key, timestamp)
        else
          hbase.getRow(table_name, key)
        end

        debug("   => #{data.inspect}")
        
        if !data.empty?
          return data
        else
          raise Rhino::Interface::HTable::RowNotFound, "No row found in '#{table_name}' with key '#{key}'"
        end
      end
      
      def scan(opts={})
        Rhino::ThriftInterface::Scanner.new(self, opts)
      end
      
      def put(key, data, is_new_record=false, timestamp=nil)
        timestamp = timestamp.to_i if timestamp
        
        if false#is_new_record
          # mutateRow won't work if there is no row, so make a row with an empty val if there was no row before
          # TODO: should probably just write the actual title and omit it from the mutations to avoid writing placeholder vals
          hbase.put(table_name, key, "title:", "PLACEHOLDER")
        end
        
        mutations = []
        data.each do |col,val|
          # see Rhino::Base#delete_attribute for an explanation of why val.nil? is checked
          next if val.nil?
          mutations << Apache::Hadoop::Hbase::Thrift::Mutation.new(:column=>col, :value=>val)
        end
        
        if timestamp
          hbase.mutateRowTs(table_name, key, mutations, timestamp)
        else
          hbase.mutateRow(table_name, key, mutations)
        end
      end
      
      # Deletes the row specified by <tt>key</tt> from the database. If <tt>columns</tt> or <tt>timestamp</tt> are specified, ...
      def delete(key, columns = nil, timestamp = nil)
        # TODO: add support for column and timestamp deletions
        if columns.nil? and timestamp.nil?
          hbase.deleteAllRow(table_name, key)
        end
      end
      
      # Deletes all of the rows in a table.
      def delete_all
        scan.each do |row|
          delete(row['key'])
        end
      end
      
      private
      def determine_column_families
        # column names are returned like 'title', not 'title:', so we have to add the colon on
        @opts[:column_families] = hbase.getColumnDescriptors(table_name).keys.collect { |col_name| "#{col_name}:" }
      end
    end
  end
end