require "spec"
require File.expand_path(File.dirname(__FILE__) + "/../lib/rhino")

include Rhino::Debug

Rhino::Base.connect("http://localhost:60010/api")

class Page < Rhino::Base
  column_family :title
  column_family :contents
  column_family :text
  column_family :meta#, :columns=>%w(keywords author encoding mime language)
end