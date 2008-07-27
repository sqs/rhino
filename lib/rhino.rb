$:.unshift File.dirname(__FILE__)

require "rubygems"
require "net/http"
require "erb"
require "xml/libxml"
#require "ruby-hbase"

require 'rhino/interface/hbase'
require 'rhino/interface/htable'
require 'rhino/interface/scanner'

# require 'rhino/rest/xml_decoder'
# require 'rhino/rest/htable'
# require 'rhino/rest/scanner'

require 'thrift/transport/tsocket.rb'
require 'thrift/protocol/tbinaryprotocol.rb'
require 'rhino/thrift/gen/Hbase'
require 'rhino/thrift/hbase'
require 'rhino/thrift/htable'
require 'rhino/thrift/scanner'


require 'rhino/debug'
require 'rhino/constraints'
require 'rhino/aliases'
require 'rhino/table'
require 'rhino/column_family'
require 'rhino/cell'
require 'rhino/version'
require 'rhino/active_record_impersonation'

module Rhino
  
end