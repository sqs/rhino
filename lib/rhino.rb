$:.unshift File.dirname(__FILE__)

require "rubygems"
require "net/http"
require "erb"
require "xml/libxml"
#require "ruby-hbase"

%w(debug xml_decoder hbase_table constraints aliases base column_family promoted_column_family version scanner).each { |f| require File.dirname(__FILE__) + "/rhino/#{f}" }

module Rhino
  
end