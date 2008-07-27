require File.dirname(__FILE__) + '/spec_helper.rb'
#require 'spec/fixtures/pages' # TODO: get real fixtures!!

describe Rhino::Model do
  after do
    Page.delete_all
  end
  
  describe "when setting up a table" do
    before do
      @table = Page
    end
  
    it "should determine the name of the table correctly" do
      @table.table_name.should == "pages"
    end
  
    it "should record column families as defined" do
      @table.column_families.should == %w(title contents links meta images)
    end
  end

  describe "when finding by key" do
    before do
      Page.create('example.com', {:title=>'hello'})
    end
  
    it "should find by key" do
      Page.find('example.com').should_not == nil
    end
  
    it "should not find by non-existent keys" do
      Page.find("this is a non-existent key").should == nil
    end
  end

  describe "when reading existing rows from HBase" do
    before do
      @key = 'some.example.com'
      @page_data = {'title:'=>'hello', 'contents:'=>'hi there', 'meta:author'=>'Alice'}
      Page.create(@key, @page_data)
      @page = Page.find(@key)
    end
    
    it "should have a data hash equivalent to that with which it was created" do
      @page.data.should == @page_data
    end
      
    after do
      Page.find(@key).destroy
    end
  end

  describe "when testing the validity of attribute names" do
    it "should reject columns that aren't in a defined column family" do
      Page.is_valid_attr_name?("addresses:home").should == false
    end
  
    it "should reject blank attribute names" do
      Page.is_valid_attr_name?("").should == false
      Page.is_valid_attr_name?(nil).should == false
    end
  
    it "should approve column families" do
      Page.is_valid_attr_name?("meta:").should == true
      Page.is_valid_attr_name?("title:").should == true
    end
  
    it "should approve columns underneath existing column families" do
      Page.is_valid_attr_name?("meta:author").should == true
      Page.is_valid_attr_name?("title:asdf").should == true
    end
  end

  describe "when working with a row" do
    before do
      @page_key = "an.example.com"
      @page_title = "Example Page"
      @page_contents = "<h1>Welcome to Example Page</h1>"
      @page_data = {:contents=>@page_contents, :title=>@page_title}
      @page = Page.create(@page_key, @page_data)
    end
    
    after do
      Page.find(@page_key).destroy
    end
  
    it "should make its attributes accessible as methods" do
      @page.title.should == @page_title
      @page.contents.should == @page_contents
    end
  
    it "should make its attributes writable" do
      @page.title = "man bites dog"
      @page.title.should == "man bites dog"
    end
    
    it "should null column family values when they are deleted" do
      @page.delete_attribute('contents:')
      @page.contents.should == nil
    end
    
    it "should remove columns entirely when they are deleted" do
      @page.meta_author = 'John'
      @page.delete_attribute('meta:author')
      # TODO: this only tests whether the value is nil, should test for existence of column
      @page.meta_author.should == nil
    end
  
    it "should set attributes that are in column families correctly" do
      author = "John Smith"
      @page.meta_author = author
      @page.meta_author.should == author
      @page.save
      Page.find(@page.key).meta_author.should == author
    end
  
    it "should make its row key accessible as a method" do
      @page.key.should == @page_key
    end
  
    it "should recognize new records" do
      new_page = Page.new('a-key', {:title=>'hello'})
      new_page.new_record?.should == true
    end
  
    it "should recognize non-new records" do
      @page.new_record?.should == false
    end
  end

  describe "when saving a row" do
    before do
      @some_key = 'example.com'
      @page = Page.create(@some_key, {:title=>'some title'})
    end
  
    it "should update title" do
      new_title = "another title"
      prev_title = @page.title
      @page.title = new_title
      @page.title.should == new_title
      @page.save
      Page.find(@some_key).title.should == new_title
      @page.title = prev_title
      @page.save
      @page.title.should == prev_title
    end
  end

  describe "when working with a new row" do
    before do
      @page_key = 'new-page'
      @page_title = 'this is a title'
      @page_contents = "<b>hello</b>"
      #@page_kind = "corporate"
      @page_data = {:title=>@page_title, :contents=>@page_contents}
    end
  
    it "should be able to be instantiated before giving data" do
      lambda { Page.new(@page_key) }.should_not raise_error(ArgumentError)    
    end
  
    it "should be a new record before save" do
      new_page = Page.new(@page_key, @page_data)
      new_page.new_record?.should == true
    end
  
    it "should not be a new record after save" do
      new_page = Page.new(@page_key, @page_data)
      new_page.save
      new_page.new_record?.should_not == true
    end
  end
  
  describe "when creating a new row" do
    it "should save the data" do
      page = Page.create('a-page', {:title=>'welcome', :contents=>'hello'})
      Page.find('a-page').title.should == 'welcome'
    end
    
    it "should not create it if find_or_create is called and the row exists" do
      page = Page.create('some-page', {:title=>'some page'})
      Page.find_or_create('some-page', {:title=>'different title'}).title.should == 'some page'
    end
    
    it "should create if find_or_create is called and the row does NOT exist" do
      # TODO: get some sort of real rollbacks so that tests don't affect the data
      if existing_page = Page.find('the-page')
        existing_page.destroy
      end
      Page.find_or_create('the-page', {:title=>'my title'}).title.should == 'my title'
    end
  end

  describe "when deleting a row" do
    before do
      @page_key = "another.example.com"
      @page_data = {:title=>'some page 12345', :contents=>'<p>welcome</p>'}
      @page = Page.new(@page_key, @page_data)
      @page.save
    end
  
    it "should delete the row" do
      Page.find(@page_key).should_not == nil
      @page.destroy
      Page.find(@page_key).should == nil
    end
  end

  describe "when working with column families" do
    before do
      @page = Page.new('yahoo.com', :title=>"Yahoo!", :contents=>"<p>yahoo</p>", :meta_author=>'filo & yang', :meta_language=>'en-US')
    end
  
    it "should structure columns properly even before saving them to the db" do
      pending
    end
  
    it "should present a ColumnFamily object" do
      @page.meta_family.class.should == Rhino::ColumnFamily
    end
  
    it "should list the columns underneath a column family" do
      @page.meta_column_names.sort.should == %w(author language)
    end
  
    it "should list the columns' full names underneath a column family" do
      @page.meta_family.column_full_names.sort.should == %w(meta:author meta:language)
    end
  end

  describe "when working with timestamps" do
    before do
      @a_while_ago = Time.now - 15 * 24 * 3600
      @even_longer_ago = Time.now - 30 * 24 * 3600
    end
  
    # it "should find normally if the timestamp is nil" do
    #   the_page = Page.find('example.com', :timestamp=>nil)
    #   the_page.should == Page.find('example.com')
    #   the_page.class.should == Page
    # end
  
    it "should fail to find if the supplied timestamp doesn't match a row" do
      nonexistent_time = Time.at(0)
      Page.find('example.com', :timestamp=>nonexistent_time).should == nil
    end
  
    it "should save and retrieve a row by timestamp" do
      key = 'google.com'
      p1 = Page.create(key, {:title=>'google a while ago'}, {:timestamp=>@a_while_ago})
      p2 = Page.create(key, {:title=>'google even longer ago'}, {:timestamp=>@even_longer_ago})
      Page.find(key, :timestamp=>@a_while_ago).title.should == 'google a while ago'
      Page.find(key, :timestamp=>@even_longer_ago).title.should == 'google even longer ago'
    end
    
    it "should find the latest row if no timestamp is specified"
  
  end

  describe "when retrieving only certain columns" do
    it "should retrieve only the requested columns"
  end
  
  describe "when using constraints" do
    before do
      blank_title = ""
      @page = Page.new('some-page', {:title=>blank_title, :contents=>"hello"})
    end
    
    it "should not save objects that violate constraints" do
      lambda { @page.save }.should raise_error(Rhino::ConstraintViolation)
    end
    
    it "should save objects that pass constraints" do
      @page.title = "any title will do"
      lambda { @page.save }.should_not raise_error(Rhino::ConstraintViolation)
    end
  end
  
  describe "when using attribute aliases" do
    it "should read the value of the target" do
      @page = Page.new('some-page')
      @page.meta_author = 'Alice'
      @page.author.should == 'Alice'
    end
    
    it "should set the value of the target" do
      @page = Page.new('some-page')
      @page.author = 'Cindy'
      @page.meta_author.should == 'Cindy'
    end
    
    it "should allow instantiation using attribute aliases" do
      @page = Page.create('some-page', :author=>'Bob', :title=>'a title')
      @page.meta_author.should == 'Bob'
      @page.author.should == 'Bob'
    end
  end
  
  describe "when testing for equality between two rows" do
    it "should find two rows equal if their key, data, and timestamp are the same" do
      Page.create('a', :title=>'b')
      Page.find('a').should == Page.find('a')
    end
    
    it "should find two rows equal even if one was create'd and one was find'ed" do
      # in this case, the only difference is that page1 (created) has @was_new_record=true, while page2 doesn't
      # that should not matter in a test of equality
      page1 = Page.create('a', :title=>'b', 'links:c'=>'d')
      page2 = Page.find('a')
      page1.should == page2
    end
    
    it "should find two rows nonequal if their keys are not the same" do
      pending "can't yet change names of keys - and maybe this will never be implemented b/c it won't make sense"
      # Page.create('a', :title=>'b', 'links:c'=>'d')
      # page1 = Page.find('a')
      # page2 = Page.find('a')
      # page2.key = 'a-different-key'
      # page1.should_not == page2
    end
    
    it "should find two rows nonequal if their data are not the same" do
      Page.create('a', :title=>'b', 'links:c'=>'d')
      page1 = Page.find('a')
      page2 = Page.find('a')
      page2.title = 'a-different-title'
      page1.should_not == page2
    end
    
    it "should find two rows nonequal if either is a new record" do
      p1 = Page.create('a', :title=>'b')
      p2 = Page.new('a', :title=>'b')
      p1.should_not == p2
    end
    
    it "should find two rows nonequal if their timestamps are not the same"
  end
end