module Rhino
  module RESTInterface
    class RowNotFound < Exception
      def initialize(msg=nil)
        super
      end
    end
  
    class HTable    
      include XmlDecoder
    
      def initialize(table_uri)
        @table_uri = table_uri

        @uri = URI.parse(table_uri)
      
        @host, @table_name = @uri.host, @uri.path.split("/").last
      end

      def name
        @table_name
      end

      ######################
      # Meta-type requests

      def start_keys
        raise NotImplementedError
      end


      def column_descriptors
        column_families = []
      
        # get the xml for the column descriptors
        response = Net::HTTP.get_response(@uri.host, "/api/#{@table_name}", @uri.port)
        body = response.body
      
        # parse the xml into a document
        doc = XML::Parser.string(body).parse
      
        doc.find("/table/columnfamilies/columnfamily").each do |node|
          colfam = {}
          colfam[:name] = node.find_first("name").content.strip.chop
          column_families << colfam
        end
        column_families
      end    

    
      #####################
      # Standard CRUD ops
    
      DEFAULT_GET_OPTIONS = {:timestamp => nil, :columns => nil}
    
      def get(key, options = {})
        opts = DEFAULT_GET_OPTIONS.merge(options)
      
        columns = Array(opts.delete(:columns)).compact
        timestamp = opts.delete(:timestamp)
        timestamp = (timestamp.to_f * 1000).to_i.to_s if timestamp
      
        Net::HTTP.start(@uri.host, @uri.port) do |session|
          columns_query = columns.map{ |name| "column=#{name}" }.join("&")

          ts_section = timestamp ? "/#{timestamp}" : ""

          query_string = "?" + columns_query
                      
          query = "/api/#{@table_name}/row/#{url_encode(key)}#{ts_section}#{query_string}"
          debug("GET #{query}")
          response = session.get(query, {"Accept" => "*/*"})

          case response.code.to_i
            when 200 #success!
              body = response.body
          
              parse_row_result(body).last
            when 204 #no data - probably an incorrect colname
              raise "Didn't get any data back - check your column names!"
            when 404
              raise Rhino::Interface::HTable::RowNotFound, "Could not find row '#{key}'"
            else
              nil
          end
        end
      end
    
      def put(key, keys_and_values, timestamp = nil)
        Net::HTTP.start(@uri.host, @uri.port) do |session|
          xml = "<columns>"
        
          ts_section = timestamp ? "/#{(timestamp.to_f * 1000).to_i}" : ""
        
          keys_and_values.each do |name, value|
            xml << "<column><name>#{name}</name><value>#{[value.to_s].pack("m")}</value></column>"          
          end
        
          xml << "</columns>"
        
          query = "/api/#{@table_name}/row/#{url_encode(key)}#{ts_section}"
          debug("PUT #{query}")
          response = session.post(query, xml, {"Content-type" => "text/xml"})
        
          case response.code.to_i
            when 200
              true
            else
              unexpected_response(response)
          end
        end
      end
        
      def delete(row, columns = nil, timestamp = nil)
        Net::HTTP.start(@uri.host, @uri.port) do |session|
          columns_query = Array(columns).compact.map{ |name| "column=#{name}" }.join("&")
        
          query = "/api/#{@table_name}/row/#{row}?#{columns_query}"
          debug("DELETE #{query}")
          response = session.delete(query)  
          case response.code.to_i
            when 202
              return true
            else
              unexpected_response(response)
          end

        end
      end
    
      #######################
      # Scanning interface
    
      def get_scanner(start_row, end_row, timestamp = nil, columns = nil)
        start_row_query = start_row ? "start_row=#{start_row}" : nil
        end_row_query = end_row ? "end_row=#{end_row}" : nil      
        timestamp_section = timestamp ? "/#{(timestamp.to_f * 1000).to_i}" : nil
        columns_section = columns ? columns.map{ |col| "column=#{col}" }.join("&") : nil

        query_string = [start_row_query, end_row_query, 
                        timestamp_section, columns_section].compact.join("&")

        path = ""

        # open the scanner
        Net::HTTP.start(@uri.host, @uri.port) do |session|
          response = session.post("/api/#{@table_name}/scanner?#{query_string}", 
            "", {"Accept" => "text/xml"}
          )
        
          case response.code.to_i
            when 201
              # redirect - grab the path and send
              Rhino::RESTInterface::Scanner.new(self, "http://#{@uri.host}:#{@uri.port}" + response["Location"])
            else
              unexpected_response(response)
          end
        end      
      end
    
    
      private
      
      def url_encode(str)
        ERB::Util.url_encode(str)
      end
    
      def unexpected_response(response)
        raise "Unexpected response code #{response.code.to_i}:\n#{response.body}"
      end
    end
  end
end