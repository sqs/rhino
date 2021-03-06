#
# Autogenerated by Thrift
#
# DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING
#

require 'thrift/protocol/tprotocol'

module Apache
  module Hadoop
    module Hbase
      module Thrift
                class TCell
                  include ThriftStruct
                  attr_accessor :value, :timestamp
                  FIELDS = {
                    1 => {:type => TType::STRING, :name => 'value'},
                    2 => {:type => TType::I64, :name => 'timestamp'}
                  }
                end

                class ColumnDescriptor
                  include ThriftStruct
                  attr_accessor :name, :maxVersions, :compression, :inMemory, :maxValueLength, :bloomFilterType, :bloomFilterVectorSize, :bloomFilterNbHashes, :blockCacheEnabled, :timeToLive
                  FIELDS = {
                    1 => {:type => TType::STRING, :name => 'name'},
                    2 => {:type => TType::I32, :name => 'maxVersions', :default => 3},
                    3 => {:type => TType::STRING, :name => 'compression', :default => 'NONE'},
                    4 => {:type => TType::BOOL, :name => 'inMemory', :default => false},
                    5 => {:type => TType::I32, :name => 'maxValueLength', :default => 2147483647},
                    6 => {:type => TType::STRING, :name => 'bloomFilterType', :default => 'NONE'},
                    7 => {:type => TType::I32, :name => 'bloomFilterVectorSize', :default => 0},
                    8 => {:type => TType::I32, :name => 'bloomFilterNbHashes', :default => 0},
                    9 => {:type => TType::BOOL, :name => 'blockCacheEnabled', :default => false},
                    10 => {:type => TType::I32, :name => 'timeToLive', :default => -1}
                  }
                end

                class TRegionInfo
                  include ThriftStruct
                  attr_accessor :startKey, :endKey, :id, :name, :version
                  FIELDS = {
                    1 => {:type => TType::STRING, :name => 'startKey'},
                    2 => {:type => TType::STRING, :name => 'endKey'},
                    3 => {:type => TType::I64, :name => 'id'},
                    4 => {:type => TType::STRING, :name => 'name'},
                    5 => {:type => TType::BYTE, :name => 'version'}
                  }
                end

                class Mutation
                  include ThriftStruct
                  attr_accessor :isDelete, :column, :value
                  FIELDS = {
                    1 => {:type => TType::BOOL, :name => 'isDelete', :default => false},
                    2 => {:type => TType::STRING, :name => 'column'},
                    3 => {:type => TType::STRING, :name => 'value'}
                  }
                end

                class BatchMutation
                  include ThriftStruct
                  attr_accessor :row, :mutations
                  FIELDS = {
                    1 => {:type => TType::STRING, :name => 'row'},
                    2 => {:type => TType::LIST, :name => 'mutations', :element => {:type => TType::STRUCT, :class => Mutation}}
                  }
                end

                class TRowResult
                  include ThriftStruct
                  attr_accessor :row, :columns
                  FIELDS = {
                    1 => {:type => TType::STRING, :name => 'row'},
                    2 => {:type => TType::MAP, :name => 'columns', :key => {:type => TType::STRING}, :value => {:type => TType::STRUCT, :class => TCell}}
                  }
                end

                class IOError < StandardError
                  include ThriftStruct
                  def initialize(message=nil)
                    super()
                    self.message = message
                  end

                  attr_accessor :message
                  FIELDS = {
                    1 => {:type => TType::STRING, :name => 'message'}
                  }
                end

                class IllegalArgument < StandardError
                  include ThriftStruct
                  def initialize(message=nil)
                    super()
                    self.message = message
                  end

                  attr_accessor :message
                  FIELDS = {
                    1 => {:type => TType::STRING, :name => 'message'}
                  }
                end

                class NotFound < StandardError
                  include ThriftStruct
                  def initialize(message=nil)
                    super()
                    self.message = message
                  end

                  attr_accessor :message
                  FIELDS = {
                    1 => {:type => TType::STRING, :name => 'message'}
                  }
                end

                class AlreadyExists < StandardError
                  include ThriftStruct
                  def initialize(message=nil)
                    super()
                    self.message = message
                  end

                  attr_accessor :message
                  FIELDS = {
                    1 => {:type => TType::STRING, :name => 'message'}
                  }
                end

              end
            end
          end
        end
