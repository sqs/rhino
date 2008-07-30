require File.dirname(__FILE__) + '/spec_helper.rb'

describe Rhino::ColumnFamily do
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
  
  it "should determine column names" do
    @page.meta_family.column_names.sort.should == %w(author language)
  end
  
  it "should determine column names in a family correctly when the column names contain extra colons" do
    @page.set_attribute('links:https://com.google/', 'link text')
    @page.links_family.column_names.should == %w(https://com.google/)
  end
end