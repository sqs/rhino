module HBase
  class Scanner
    include XmlDecoder
    
    def initialize(table, scanner_uri)
      @table, @scanner_uri = table, scanner_uri
    end
    
    def close
      
    end
    
    def next
      
    end
    
    def each
      parsed_uri = URI.parse(@scanner_uri)
      Net::HTTP.start(parsed_uri.host, parsed_uri.port) do |session|
        while true
          response = session.post(@scanner_uri, "")

          case response.code.to_i
            when 404
              # over
              break
            when 200
              # item
              yield *parse_row_result(response.body)
            else
              # error
              raise "Unexpected response code #{response.code}, body:\n#{response.body}"
          end
        end
      end
    end

    private
    
    # def parse_row(xml)
    #   doc = REXML::Document.new(xml)
    # 
    #   result = {}
    # 
    #   doc.root.each_element("/row/column") do |column|
    #     name = column.get_elements("name")[0].text.strip
    #     value = column.get_elements("value")[0].text.strip.unpack("m").first
    #     result[name] = value
    #   end
    #   
    #   [doc.root.get_elements("name")[0].text.strip, result]
    # end
    
  end
end