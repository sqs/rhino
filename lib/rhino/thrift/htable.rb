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
        
        raise(ArgumentError, "get requires a key") if key.nil? or key==''
      
        columns = Array(opts.delete(:columns)).compact

        timestamp = opts.delete(:timestamp)
        timestamp = timestamp.to_i if timestamp
        
        rowresult = if timestamp
          hbase.getRowTs(table_name, key, timestamp)
        else
          hbase.getRow(table_name, key)
        end

        debug("   => #{rowresult.inspect}")
        
        # TODO: handle timestamps on a per-cell level
        if !rowresult.columns.empty?
          return prepare_rowresult(rowresult)
        else
          raise Rhino::Interface::HTable::RowNotFound, "No row found in '#{table_name}' with key '#{key}'"
        end
      end
      
      def scan(opts={})
        Rhino::ThriftInterface::Scanner.new(self, opts)
      end
      
      def put(key, data, timestamp=nil)
        timestamp = timestamp.to_i if timestamp
        
        mutations = data.collect do |col,val|
          # if the value is nil, that means we are deleting that cell
          mutation_data = {:column=>col}
          if val.nil?
            mutation_data[:isDelete] = true
          else
            raise(ArgumentError, "column values must be strings or nil") unless val.is_a?(String)
            mutation_data[:value] = val
          end
          Apache::Hadoop::Hbase::Thrift::Mutation.new(mutation_data)
        end
        
        if timestamp
          hbase.mutateRowTs(table_name, key, mutations, timestamp)
        else
          hbase.mutateRow(table_name, key, mutations)
        end
      end
      
      # Deletes the row at +key+ from the table.
      def delete_row(key)
        hbase.deleteAllRow(table_name, key)
      end
      
      # Deletes all of the rows in a table.
      def delete_all_rows
        scan.each do |row|
          delete_row(row['key'])
        end
      end
      
      # Takes a Apache::Hadoop::Hbase::Thrift::TRowResult instance and returns a hash like:
      # {'title:'=>'Some title', 'timestamp'=>1938711819342}
      def prepare_rowresult(rowresult)
        result_columns = rowresult.columns
        data = {}
        result_columns.each { |name, tcell| data[name] = tcell.value }
        
        # consider the timestamp to be the timestamp of the most recent cell
        data['timestamp'] = -1
        result_columns.values.each do|tcell|
          data['timestamp'] = tcell.timestamp if data['timestamp'] < tcell.timestamp
        end
        
        return data
      end
      
      private
      def determine_column_families
        # column names are returned like 'title', not 'title:', so we have to add the colon on
        @opts[:column_families] = hbase.getColumnDescriptors(table_name).keys.collect { |col_name| "#{col_name}:" }
      end
    end
  end
end