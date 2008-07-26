module HBase
  module XmlDecoder
    def parse_row_result(xml)
      doc = XML::Parser.string(xml).parse

      name_node = doc.root.find_first("/row/name")
      name = name_node ? name_node.content.strip : nil
      
      values = {}
      
      doc.find("/row/column").each do |node|
        values[node.find_first("name").content.strip.unpack("m")] = node.find_first("value").content.strip.unpack("m").first
      end
      
      [name, values]
    end
  end
end