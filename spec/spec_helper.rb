require "rubygems"
require "spec"
require File.expand_path(File.dirname(__FILE__) + "/../lib/rhino")

include Rhino::Debug

Rhino::Base.connect("http://localhost:60010/api")

class Link < Rhino::PromotedColumnFamily
  def url
    url_parts = key.split('/')
    backwards_host = url_parts.shift
    path = url_parts.join('/')
    host = backwards_host.split('.').reverse.join('.')
    "http://#{host}/#{path}"
  end
end

class Page < Rhino::Base
  column_family :title
  column_family :contents
  column_family :links
  column_family :meta
  
  has_many :links, Link
end

page_key = 'example.com'
page_data = {'contents:'=>"<h1>Welcome to Example Page</h1>",
            'title:'=>'Example Page', 'meta:author'=>'John Smith', 'links:com.example.www/path'=>'Click here'}
unless page = Page.find(page_key) and page.data == page_data
  puts "Creating mock Page with key='#{page_key}' and data #{page_data.inspect}"
  Page.create(page_key, page_data)
end