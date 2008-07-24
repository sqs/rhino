require File.dirname(__FILE__) + '/spec_helper.rb'

describe Rhino::Base do
  describe "when setting up a table" do
    before do
      @table = Page
    end
  
    it "should determine the name of the table correctly" do
      @table.table_name.should == "pages"
    end
  
    it "should record column families as defined" do
      @table.column_families.should == %w(title contents links meta)
    end
  end

  describe "when finding by key" do
    before do
      @table = Page
      @key = 'example.com'
    end
  
    it "should find by key" do
      @table.find(@key).should_not == nil
    end
  
    it "should not find by non-existent keys" do
      @table.find("this is a non-existent key").should == nil
    end
  end


  describe "when testing the validity of column names" do
    it "should reject columns that aren't in a defined column family" do
      Page.is_valid_column_name?("addresses:home").should == false
    end
  
    it "should reject blank column names" do
      Page.is_valid_column_name?("").should == false
      Page.is_valid_column_name?(nil).should == false
    end
  
    it "should approve column families" do
      Page.is_valid_column_name?("meta:").should == true
      Page.is_valid_column_name?("title:").should == true
    end
  
    it "should approve columns underneath existing column families" do
      Page.is_valid_column_name?("meta:author").should == true
      Page.is_valid_column_name?("title:asdf").should == true
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
  
    it "should make its columns accessible as methods" do
      @page.title.should == @page_title
      @page.contents.should == @page_contents
    end
  
    it "should make its columns writable" do
      @page.title = "man bites dog"
      @page.title.should == "man bites dog"
    end
  
    it "should set columns that are namespaced into column families correctly" do
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
      @page_key = 'example.com'
      @page = Page.find(@page_key)
    end
  
    it "should update title" do
      new_title = "another title"
      prev_title = @page.title
      @page.title = new_title
      @page.title.should == new_title
      @page.save
      Page.find(@page_key).title.should == new_title
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
      Page.find(key).title.should == 'google a while ago'
      p1.destroy; p2.destroy
    end
  
    it "should be able to save existing rows with a specific timestamp"
  end

  describe "when retrieving only certain columns" do
    it "should retrieve only the requested columns"
  end
end