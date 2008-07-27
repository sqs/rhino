require 'spec/spec_helper.rb'

# TODO these tests should not be dependent on Rhino::Base (Page is a subclass of Base)
describe Rhino::Interface::HTable do
  before do
    @page_htable = Page.htable
  end
  
  after do
    @page_htable.delete_all
  end
  
  describe "when getting rows" do
    it "should raise RowNotFound for nonexistent rows" do
      lambda { @page_htable.get('this row key does not exist') }.should raise_error(Rhino::Interface::HTable::RowNotFound)
    end
  end
  
  describe "when deleting all rows" do
    before do
      @page_htable.put('a', {'title:'=>'abc'})
      @page_htable.put('b', {'title:'=>'bcd'})
      @page_htable.put('c', {'title:'=>'cde'})
    end
    
    it "should remove all rows" do
      @page_htable.get('a').should_not == nil
      @page_htable.delete_all
      lambda { @page_htable.get('a') }.should raise_error(Rhino::Interface::HTable::RowNotFound)
      @page_htable.scan.collect.should == []
    end
  end
  
  describe "when deleting single rows" do  
    before do
      @some_key = 'some-key'
      @page_htable.put(@some_key, {'title:'=>'abc'})
    end
    
    it "should remove all versions and columns when only key is specified and only one version exists" do
      @page_htable.get(@some_key).should_not == nil
      @page_htable.delete(@some_key)
      lambda { @page_htable.get(@some_key) }.should raise_error(Rhino::Interface::HTable::RowNotFound)
    end
    
    it "should remove all versions and columns when only key is specified and multiple versions exist"
  end
  
  describe "when putting existing rows" do
    it "should delete cells that previously existed if their value is changed to nil" do
      key = 'example.com'
      @page_htable.put(key, {'title:'=>'howdy', 'links:com.google'=>'Google'}, true)
      @page_htable.get(key).keys.include?('links:com.google').should == true
      # the cell has been deleted
      @page_htable.put(key, {'title:'=>'howdy', 'links:com.google'=>nil}, false)
      @page_htable.get(key).keys.include?('links:com.google').should == false
    end
  end
  
  describe "when putting new rows" do
    describe "when the row is new" do
      it "should create the row before mutating its values"
    end
    
    it "should update the values" do
      key = 'hi.example.com'
      @page_htable.put(key, {'title:'=>'howdy'}, true)
      @page_htable.get(key)['title:'].should == 'howdy'
      @page_htable.put(key, {'title:'=>'goodbye'}, false)
      @page_htable.get(key)['title:'].should == 'goodbye'
    end
  end
end