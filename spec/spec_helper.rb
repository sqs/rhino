require "spec"
require File.expand_path(File.dirname(__FILE__) + "/../lib/rhino")

include Rhino::Debug

Rhino::Base.connect("http://localhost:60010/api")

class Page < Rhino::Base
  column_family :title
  column_family :contents
  column_family :links
  column_family :meta#, :columns=>%w(keywords author encoding mime language)
end

page_key = 'example.com'
page_data = {:contents=>"<h1>Welcome to Example Page</h1>",
            :title=>'Example Page', :meta_author=>'John Smith'}
unless page = Page.find(page_key) and page.data == page_data
  puts "Creating mock Page with key='#{page_key}' and data #{page_data.inspect}"
  Page.create(page_key, page_data)
end