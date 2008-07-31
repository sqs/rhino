require File.dirname(__FILE__) + '/spec_helper.rb'

describe Rhino::Scanner do
  before do
    @p1 = Page.create('com.example', :title=>'example')
    @p2 = Page.create('com.google', :title=>'Google')
    @p3 = Page.create('com.microsoft', :title=>'Microsoft')
    @p4 = Page.create('com.yahoo', :title=>'Yahoo')
  end
  
  describe "when getting all rows" do
    before do
      @all_pages = Page.get_all
    end
    
    it "should return all rows" do
      @all_pages.should == [@p1, @p2, @p3, @p4]
    end
  end
  
  describe "when scanning all rows" do
    it "should return all rows" do
      Page.scan.collect.should == [@p1, @p2, @p3, @p4]
    end
  end
  
  describe "when scanning with a start row specified" do    
    it "should show rows including and after the start row" do
      Page.scan(:start_row=>'com.google').collect.should == [@p2, @p3, @p4]
    end
  end
  
  describe "when scanning with a start row and an stop row specified" do
    it "should return all rows between the start row and stop row (inclusive)" do
      Page.scan(:start_row=>'com.google', :stop_row=>'com.yahoo').collect.should == [@p2, @p3]
    end
  end
  
  describe "when scanning with an stop row specified" do
    it "should only show rows up to and including the stop row" do
      Page.scan(:stop_row=>'com.microsoft').collect.should == [@p1, @p2]
    end
  end
end