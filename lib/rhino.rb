$:.unshift File.dirname(__FILE__)

require "rubygems"

# get Class.cattr_accessor from ActiveSupport
require 'active_support/core_ext/string'
require 'active_support/core_ext/array/extract_options.rb'
require 'active_support/core_ext/class/attribute_accessors.rb'
class Array; include ActiveSupport::CoreExtensions::Array::ExtractOptions; end


require 'rhino/interface/hbase'
require 'rhino/interface/htable'
require 'rhino/interface/scanner'

require 'thrift/transport/tsocket.rb'
require 'thrift/protocol/tbinaryprotocol.rb'
require 'rhino/thrift/gen/Hbase'
require 'rhino/thrift/hbase'
require 'rhino/thrift/htable'
require 'rhino/thrift/scanner'


require 'rhino/debug'
require 'rhino/constraints'
require 'rhino/attr_names'
require 'rhino/scanner'
require 'rhino/aliases'
require 'rhino/model'
require 'rhino/column_family'
require 'rhino/cell'
require 'rhino/cells_proxy'
require 'rhino/version'
require 'rhino/active_record_impersonation'

RHINO_DEBUG = true unless defined?(RHINO_DEBUG)
include Rhino::Debug

module Rhino
  
end