require File.dirname(__FILE__) + '/spec_helper.rb'

describe Rhino::Cell do
  describe "when working with a has_many relationship" do
    before do
      @key = 'hasmany.example.com'
      @page = Page.create(@key, {:title=>'Has Many Example', 'links:com.example.an/path'=>'Click now',
                                 'links:com.google.www/search'=>'Search engine'})
    end
    
    after do
      Page.delete_all
    end
  
    it "should return a list of objects that it has_many of" do
      @page.links.keys.sort.should == %w(com.example.an/path com.google.www/search)
    end
    
    it "should allow retrieval by key" do
      @page.links.find('com.example.an/path').contents.should == 'Click now'
      @page.links.find('com.google.www/search').key.should == 'com.google.www/search' 
    end
        
    describe "when looping over the collection" do
      it "should return each object" do
        link_keys = []
        @page.links.each { |link| link_keys << link.key }
        link_keys.sort.should == %w(com.example.an/path com.google.www/search)
      end
    end
    
    describe "when changing attributes" do
      def change_the_key
        @page.links.find('com.google.www/search').key = 'com.google.www/another/path'
        @page.save
        @reloaded_page_link_keys = Page.find(@key).links.keys
      end
    
      it "should save key changes propagated by the contained model" do
        change_the_key
        @reloaded_page_link_keys.include?('com.google.www/another/path').should == true
      end
      
      it "should remove the old column when changing the key" do
        pending
        change_the_key
        @reloaded_page_link_keys.include?('com.google.www/search').should == false
      end
    
      it "should save contents changes propagated by the contained model" do
        goog_link = @page.links.find('com.google.www/search')
        goog_link.contents = 'Google'
        goog_link.save
        Page.find(@key).links.find('com.google.www/search').contents.should == 'Google'
      end
    end
    
    
    it "should not be a new record after it has been saved" do
      pending
      @page.links.find('com.google.www/search').new_record?.should == false
    end
    
    it "should be a new record before it has been saved" do
      pending
      @page.set_attribute('links:com.apple', 'New link')
      @page.links.find('com.apple').new_record?.should == true
    end
    
    describe "when subclassing Cell" do
      it { @page.links.find('com.example.an/path').class.should == Link }
      
      it "should allow custom methods to be defined on the subclass" do
        @page.links.find('com.example.an/path').url.should == 'http://an.example.com/path'
      end
    end
    
    describe "when a model has_many of two things" do
      before do
        @page.images.create_multiple('com.apple/logo.png'=>'Apple Logo', 'com.google/logo.png'=>'Google Logo')
      end
      
      it "should not confuse cells from different subclasses" do
        @page.links.find('com.apple/logo.png').should == nil
        @page.images.find('com.google.www/search').should == nil
      end
    end
    
    it "should allow retrieval of the containing model by the name specified in belongs_to" do
      @page.links.find('com.example.an/path').page.should == @page
    end
    
    it "should allow retrieval of the containing model by the generic accessor #row" do
      @page.links.find('com.example.an/path').row.should == @page
    end
  
    describe "adding objects" do
      it "should allow a new cell to be added" do
        @page.links.create('com.yahoo', "Yahoo")
        the_link = @page.links.find('com.yahoo')
        the_link.contents.should == 'Yahoo'
      end
      
      it "should allow multiple cells to be added by hash" do
        @page.links.create_multiple('com.yahoo'=>'Yahoo', 'com.cisco'=>'Cisco')
        @page.links.find('com.yahoo').contents.should == 'Yahoo'
        @page.links.find('com.cisco').contents.should == 'Cisco'
      end
      
      it "should determine whether a cell is a new_record?"
      
      it "should determine new_record? status of cells independently from their parent class" do
        pending
        apache_link = @page.links.build('org.apache', 'ASF')
        apache_link.new_record?.should == true
      end
    end
    
    it "should allow deletion from the list of objects" do
      @page.links.create('com.microsoft', 'Microsoft')
      @page.links.find('com.microsoft').contents.should == 'Microsoft'
      @page.links.find('com.microsoft').destroy
      @page.links.find('com.microsoft').should == nil
    end
    
    it "should allow retrieval of all of the column names"
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
end