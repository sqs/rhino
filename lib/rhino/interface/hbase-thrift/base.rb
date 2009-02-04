module Rhino
  module HBaseThriftInterface
    class Base < Rhino::Interface::Base
      THRIFT_RETRY_COUNT = 3
      attr_reader :host, :port, :client
      
      def initialize(host, port)
        debug("Rhino::HBaseThriftInterface::Base.new(#{host.inspect}, #{port.inspect})")
        @host = host
        @port = port
        connect()
      end
      
      def connect
        transport = TBufferedTransport.new(TSocket.new(host, port))
        protocol = TBinaryProtocol.new(transport)
        @client = Apache::Hadoop::Hbase::Thrift::Hbase::Client.new(protocol)
        transport.open()
      end

      def connect
        count = 1
        while @client == nil and count < THRIFT_RETRY_COUNT
          transport = TBufferedTransport.new(TSocket.new(host, port))
          protocol = TBinaryProtocol.new(transport)
          @client = Apache::Hadoop::Hbase::Thrift::Hbase::Client.new(protocol)
          begin
            transport.open()
          rescue Thrift::TransportException
            @client = nil
            debug("Could not connect to HBase.  Retrying in 5 seconds..." + count.to_s + " of " + THRIFT_RETRY_COUNT.to_s)
            sleep 5
            count = count + 1
          end
        end
        if count == THRIFT_RETRY_COUNT
          debug("Failed to connect to HBase after " + THRIFT_RETRY_COUNT.to_s + " tries.")
        end
      end
      
      def table_names
        client.getTableNames()
      end

      def method_missing(method, *args)
        debug("#{self.class.name}#method_missing(#{method.inspect}, #{args.inspect})")
        begin
          connect() if not @client
          client.send(method, *args) if @client
        rescue Thrift::TransportException
          @client = nil
          connect()
          client.send(method, *args) if @client
        end
      end
    end
  end
end