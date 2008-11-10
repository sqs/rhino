module Rhino
  module HBaseThriftInterface
    class Base < Rhino::Interface::Base
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
      
      def table_names
        client.getTableNames()
      end
      
      def method_missing(method, *args)
        debug("#{self.class.name}#method_missing(#{method.inspect}, #{args.inspect})")
        client.send(method, *args)
      end
    end
  end
end