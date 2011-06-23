module Rhino
  module HBaseThriftInterface
    class Scanner
      include Enumerable
      
      attr_reader :htable, :columns
      
      def initialize(htable, columns, opts={})
        @htable = htable
        @opts = opts
        @opts[:start_row] ||= ''
        @columns = columns
        #raise @opts[:columns].inspect
        
        open_scanner
      end
      
      def open_scanner
        @scanner = if @opts[:stop_row]
          htable.hbase.scannerOpenWithStop(htable.table_name, @opts[:start_row], @opts[:stop_row], @columns)
        else
          htable.hbase.scannerOpen(htable.table_name, @opts[:start_row], @columns)
        end
      end
      
      # Returns the next row in the scanner in the format specified below. Note that the row key is 'key', not 'key:'.
      #   {'key'=>'the row key', 'col1:'=>'val1', 'col2:asdf'=>'val2'}
      def next_row
        begin
          rowresult = htable.hbase.scannerGet(@scanner)
          #scannerGet returns list of Apache::Hadoop::Hbase::Thrift::TRowResult. just use the first one
          raise Apache::Hadoop::Hbase::Thrift::IOError.new if rowresult.length == 0
          rowresult = rowresult[0] if rowresult.class == Array
          row = @htable.prepare_rowresult(rowresult)          
          row['key'] = rowresult.row
          return row
        #scannerGet never throws NotFound. only IOError or IllegalArgument
        rescue Apache::Hadoop::Hbase::Thrift::IOError
          htable.hbase.scannerClose(@scanner)
          return nil
        end
      end
      
      def each
        while row = next_row()
          yield(row)
        end
      end
    end
  end
end