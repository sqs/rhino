require File.dirname(__FILE__) + '/spec_helper.rb'
# TODO: get real fixtures!!

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

  describe "when getting by key" do
    before do
      Page.create('example.com', {:title=>'hello'})
    end
  
    it "should get by key" do
      Page.get('example.com').should_not == nil
    end
  
    it "should not get by non-existent keys" do
      Page.get("this is a non-existent key").should == nil
    end
  end
  
  
  describe "when introspecting a row" do
    it "should list the columns present" do
      # TODO: timestamp should not be in this list
      page = Page.create('somekey', :title=>'a', :meta_author=>'b', 'links:com.google'=>'c')
      page.columns.sort.should == %w(links:com.google meta:author title:)
    end
  end

  describe "when reading existing rows from HBase" do
    before do
      @key = 'some.example.com'
      @page_data = {'title:'=>'hello', 'contents:'=>'hi there', 'meta:author'=>'Alice'}
      Page.create(@key, @page_data)
      @page = Page.get(@key)
    end
    
    it "should have a data hash equivalent to that with which it was created" do
      @page.title.should == @page_data['title:']
      @page.contents.should == @page_data['contents:']
      @page.meta_author.should == @page_data['meta:author']
    end
      
    after do
      Page.get(@key).destroy
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
      Page.get(@page_key).destroy
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
    
    it "should null column values when they are deleted" do
      # TODO: change this behavior so that it entirely deletes the attribute
      @page.meta_author = 'John'
      @page.delete_attribute('meta:author')
      @page.meta_author.should == nil
    end
  
    it "should set attributes that are in column families correctly" do
      author = "John Smith"
      @page.meta_author = author
      @page.meta_author.should == author
      @page.save
      Page.get(@page.key).meta_author.should == author
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
  
  describe "when changing the key of an existing row" do
    before do
      @page = Page.create('abc', {:title=>'old title'})
    end
    
    it "should save under the new key" do
      @page.key = 'xyz'
      @page.title = 'new title'
      @page.save
      Page.get('xyz').title.should == 'new title'
    end
    
    it "should keep the old data at the old key" do
      @page.key = 'xyz'
      @page.save
      Page.get('abc').title.should == 'old title'
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
      Page.get(@some_key).title.should == new_title
      @page.title = prev_title
      @page.save
      @page.title.should == prev_title
    end
    
    it "should set was_new_record to true if it previously was a new record" do
      Page.create('a', :title=>'b').was_new_record?.should == true
    end
    
    it "should not set was_new_record to true if it previously was not a new record" do
      Page.new('a', :title=>'b').save
      page = Page.get('a')
      page.title = 'c'
      page.save
      page.was_new_record?.should == false
    end
    
    it "should return true if it successfully saved the row" do
      Page.new('a', :title=>'b').save.should == true
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
      Page.get('a-page').title.should == 'welcome'
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
      Page.get(@page_key).should_not == nil
      @page.destroy
      Page.get(@page_key).should == nil
    end
  end

  

  describe "when working with timestamps" do
    before do
      now = (Time.now.to_f * 1000).to_i
      @a_while_ago = now - 1000
      @even_longer_ago = now - 30000
    end
  
    it "should get normally if the timestamp is nil" do
      pending
      the_page = Page.get('example.com', :timestamp=>nil)
      the_page.should == Page.get('example.com')
      the_page.class.should == Page
    end
  
    it "should fail to get if the supplied timestamp doesn't match a row" do
      nonexistent_time = Time.at(0)
      Page.get('example.com', :timestamp=>nonexistent_time).should == nil
    end
  
    it "should save and retrieve a row by timestamp" do
      key = 'google.com'
      p1 = Page.create(key, {:title=>'google a while ago', :timestamp=>@a_while_ago})
      p2 = Page.create(key, {:title=>'google even longer ago', :timestamp=>@even_longer_ago})
      Page.get(key, :timestamp=>@a_while_ago).title.should == 'google a while ago'
      Page.get(key, :timestamp=>@even_longer_ago).title.should == 'google even longer ago'
    end
    
    it "should return its timestamp" do
      Page.create('abc', {:title=>'hello'})
      Page.get('abc').timestamp.should be_close((Time.now.to_f * 1000).to_i, 100)
    end
    
    it "should get the latest row if no timestamp is specified"
  
  end

  describe "when retrieving only certain columns" do
    it "should retrieve only the requested columns"
  end
  
  describe "when testing for equality between two rows" do
    it "should find two rows equal if their key, data, and timestamp are the same" do
      Page.create('a', :title=>'b')
      Page.get('a').should == Page.get('a')
    end
    
    it "should find two rows equal even if one was create'd and one was get'ed" do
      pending
      # page1 doesn't know its timestamp, so they cannot be equal
      page1 = Page.create('a', :title=>'b', 'links:c'=>'d')
      page2 = Page.get('a')
      page1.should == page2
    end
    
    it "should find two rows nonequal if their keys are not the same" do
      pending "can't yet change names of keys - and maybe this will never be implemented b/c it won't make sense"
      # Page.create('a', :title=>'b', 'links:c'=>'d')
      # page1 = Page.get('a')
      # page2 = Page.get('a')
      # page2.key = 'a-different-key'
      # page1.should_not == page2
    end
    
    it "should find two rows nonequal if their data are not the same" do
      Page.create('a', :title=>'b', 'links:c'=>'d')
      page1 = Page.get('a')
      page2 = Page.get('a')
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
  
  describe "when subclassing Model" do
    before(:all) do
      class SpecialPage < Page; @table_name = 'page'; def special?; true; end; end
    end
    
    it "should have the same column families as the parent class" do
      SpecialPage.column_families.should == ["title", "contents", "links", "meta", "images"]
    end
    
    it "should have the methods defined on the subclass" do
      SpecialPage.new('somespecialpage').special?.should == true
    end
  end
end