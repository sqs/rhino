#Rhino - a Ruby ORM for HBase

Rhino is a Ruby object-relational mapping (ORM) for [HBase](http://www.hbase.org).

## Support & contact

Author: Quinn Slack qslack@qslack.com[mailto:qslack@qslack.com]

Contributors: Dru Jensen

## Getting started

### Installing HBase and Thrift

Since Rhino uses the HBase Thrift API, you must first install both HBase and Thrift. Downloading the latest trunk revisions of each is recommended, but if you encounter problems, try using the latest stable release instead. Here are the basic steps for installing both:

	#install hbase - this URL may change. to get the best URL, check http://www.apache.org/dyn/closer.cgi/hbase/
	wget http://mirrors.kahuki.com/apache//hbase/stable/hbase-0.90.3.tar.gz 
	tar xvf hbase-0.90.3.tar.gz
	cd hbase-0.90.3
	cd ..

	#install thrift - this assumes that you already have boost installed
	wget http://www.apache.org/dyn/closer.cgi?path=/thrift/0.6.1/thrift-0.6.1.tar.gz
	tar xvf thrift-0.6.1.tar.gz
	cd thrift-0.6.1
	./configure
	make
	sudo make install
	cd ..

	#start hbase and hbase-thrift servers
	cd hbase-0.90.3
	bin/start-hbase.sh
	bin/hbase thrift start
	
TODO: set up an hbase server in ec2 so that the hbase install isn't needed

### Installing Rhino

Since Rhino is not yet packaged as a gem, you will have to run:
  
	git clone git@github.com:arschles/rhino.git

and then in your code:

	require 'rhino/lib/rhino.rb'
  
## Usage

### Connect to HBase

The following code points Rhino to the Thrift server you just started (which by default listens on localhost:9090).
  
  Rhino::Model.connect('localhost', 9090)
  
### Describe your table

A class definition like:

	class Page < Rhino::Model
		include Rhino::Constraints

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

is mapped to the following HBase table as described by the [HBase Query Language](http://wiki.apache.org/lucene-hadoop/HBase/HBaseShell)

	CREATE TABLE pages(title:, contents:, links:, meta:, images:);
  
or as described by the HBase shell language:
  
	create 'pages', 'title', 'contents', 'links', 'meta', 'images'

### Basic operations

#### Getting records

	page = Page.get('some-page')
	all_pages = Page.get_all()
  
#### Creating new records

	# data can be specified in the second argument of Page.new...
	page = Page.new('the-row-key', {:title=>"my title"})
	# ...or as attributes on the model
	page.contents = "<p>welcome</p>"
	page.save

#### Reading and updating attributes

	page = Page.get('some-key')
	puts "the old title is: #{page.title}"
	page.title = "another title"
	page.save
	puts "the new title is: #{page.title}"

You can also read from and write to specific columns in a column family.
Since we already defined the *meta:* column family, Rhino knows we want to set the *meta:author* column:

	page = Page.get('some-key')
	page.meta_author = "John Doe"
	page.save
	puts "the author is: #{page.meta_author}"
  
### has_many and belongs_to

In the model definition above, we stated that a Page *has_many :links* and *has_many :images*. We can 
define what a Link and an Image is with greater detail now.

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
  
Now that we've defined *Link* and *Image*, we can work with them easily. The following code adds a link to the page *com.example*, which when written to HBase becomes a cell in the *links:* column family named *links:com.google* with the contents *search engine*.

	page = Page.get('com.example')
	page.links.create('com.google', 'search engine')
  
You can also iterate over the collection of links. In this example, we use *Link#url*, a method we defined on the Link class
to convert from the common *com.example/path* URL storage style to *example.com/path*.

	page.links.each do |link|
		puts "Link to #{link.url} with text: '#{link.contents}'"
	end
  
You can also get a specific link.

	google_link_text = page.get('com.google').contents

### Setting timestamps and retrieving by timestamp
  
First, let's create some Pages with different timestamps.

	a_week_ago = Time.now - 7 * 24 * 3600
	a_month_ago = Time.now - 30 * 24 * 3600

	newer_page = Page.create('google.com', {:title=>'newer google'}, {:timestamp=>a_week_ago})
	older_page = Page.create('google.com', {:title=>'older google'}, {:timestamp=>a_month_ago})
  
Now you can *get* by the timestamps you just set.

	Page.get('google.com', :timestamp=>a_week_ago).title # => "newer google"
	Page.get('google.com', :timestamp=>a_month_ago).title # => "older google"
  
If you call *get* with no arguments, you will get the most recent Page.

	Page.get('google.com').title # => "newer google"
  
## More information

Read the specs in the spec/ directory to see more usage examples. Also look at the spec models in spec/spec_helper.rb. Note that to run the specs, you will need to create the necessary table and column
families in HBase before you continue. To do so, launch the HBase shell:
	
	$HBASE_DIR/bin/hbase shell
	
and execute:

	create 'pages', 'title', 'contents', 'links', 'meta', 'images'

