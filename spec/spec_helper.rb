require "rubygems"
require "spec"
require File.expand_path(File.dirname(__FILE__) + "/../lib/rhino")

include Rhino::Debug

Rhino::Table.connect('localhost', 9090) unless Rhino::Table.connected?

class Link < Rhino::Cell
  belongs_to :page
  
  def url
    url_parts = key.split('/')
    backwards_host = url_parts.shift
    path = url_parts.join('/')
    host = backwards_host.split('.').reverse.join('.')
    "http://#{host}/#{path}"
  end
end

class Image < Rhino::Cell
  belongs_to :page
end

class Page < Rhino::Table
  column_family :title
  column_family :contents
  column_family :links
  column_family :meta
  column_family :images
  
  alias_attribute :author, 'meta:author'
  
  has_many :links, Link
  has_many :images, Image
  
  constraint(:title_required) { |page| page.title and !page.title.empty? }
end