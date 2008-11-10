require 'spec/spec_helper.rb'

describe Rhino::Interface::Scanner do
  before do
    @page_table = Page.table
    @page_table.put('com.apple', {'title:'=>'apple'})
    @page_table.put('com.google', {'title:'=>'google'})
    @page_table.put('com.microsoft', {'title:'=>'microsoft'})
    @page_table.put('com.yahoo', {'title:'=>'yahoo'})
  end
  
  after do
    @page_table.delete_all_rows
  end
  
  describe "scanning all rows" do
    it "should return all rows" do
      rows = @page_table.scan.collect
      rows.collect { |row| row['title:'] }.should == %w(apple google microsoft yahoo)
      rows.collect { |row| row['key'] }.should == %w(com.apple com.google com.microsoft com.yahoo)
    end
  end
  
  describe "when scanning with only a start row specified" do
    it "should return all rows including and after the start row" do
      rows = @page_table.scan(:start_row=>'com.google')
      rows.collect { |row| row['key'] }.should == %w(com.google com.microsoft com.yahoo)
    end
  end
  
  describe "when scanning with a start row and a stop row specified" do
    it "should return all rows between the start row (inclusive) and stop row (exclusive)" do
      rows = @page_table.scan(:start_row=>'com.google', :stop_row=>'com.yahoo')
      rows.collect { |row| row['key'] }.should == %w(com.google com.microsoft)
    end
  end
  
  describe "when scanning with only a stop row specified" do
    it "should return all rows up to but not including the stop row" do
      rows = @page_table.scan(:stop_row=>'com.microsoft')
      rows.collect { |row| row['key'] }.should == %w(com.apple com.google)
    end
  end
  
  describe "when no rows in the table exist" do
    before do
      @page_table.delete_all_rows
    end
    
    it "should not raise an error" do
      lambda { @page_table.scan }.should_not raise_error
    end
    
    it "should return an empty array" do
      @page_table.scan.collect.should == []
    end
  end
  
  if ENV['RUN_HUGE_TEST']
    describe "when many rows exist" do
      before do
        (1..45000).each do |n|
          @page_table.put("item#{n}", {'title:'=>"title#{n}"})
        end
      end
      
      it "should scan all rows without an error" do
        lambda { @page_table.scan.each do |row|
          puts row.title
        end }.should_not raise_error
      end
      
    end
  end
end