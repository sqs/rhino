$:.unshift File.dirname(__FILE__)

require "rubygems"
require 'active_support'

# cherry-pick ActiveSupport modules if we can (throws errors under rails 2.3)
# only need Class.cattr_accessor from ActiveSupport
# require 'active_support/core_ext/string'
# require 'active_support/core_ext/array/extract_options.rb'
# require 'active_support/core_ext/class/attribute_accessors.rb'
# class Array; include ActiveSupport::CoreExtensions::Array::ExtractOptions; end


require 'rhino/interface/base'
require 'rhino/interface/table'
require 'rhino/interface/scanner'

require 'thrift/transport/tsocket.rb'
require 'thrift/protocol/tbinaryprotocol.rb'
require 'rhino/interface/hbase-thrift/gen/Hbase'
require 'rhino/interface/hbase-thrift/base'
require 'rhino/interface/hbase-thrift/table'
require 'rhino/interface/hbase-thrift/scanner'


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

#when in production, probably want to set RHINO_DEBUG = false in environment.rb
RHINO_DEBUG = true unless defined?(RHINO_DEBUG)
include Rhino::Debug

module Rhino
  
end